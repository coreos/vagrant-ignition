#!/usr/bin/ruby
require 'zlib'

# Note: gpt and gpt2 are the primary and secondary headers respectively
class IgnitionDiskGenerator
  # These are variables needed across both function
  @@first_usable_lba
  @@gpt_entrysize
  @@gpt_max_entries
  @@gpt_length
  @@last_usable_lba

  def self.create_disk(ignition_name, config_drive)
    # Constants
    @first_usable_lba  = 2048
    @gpt_entrysize     = 128
    @gpt_max_entries   = 128
    gpt_lba            = 1
    arr_lba            = 2
    lba_size           = 512
    pmbr_length        = lba_size
    @gpt_length        = lba_size
    arr_length         = @gpt_max_entries * @gpt_entrysize
    minimum_disk_size  = 1536000                                                             # ~1.5M; there are issues with udev not registering the device if it is less than this...
    partitioner_reserved_space = (@first_usable_lba * lba_size) + (@gpt_length + arr_length) # this is space reserved by the partition tables and arrays
    part_label         = "Ignition Config Drive"
    part_label_encoded = part_label.encode("utf-16le").bytes
 
    ignition_conf = File.open(ignition_name, "r")
    contents = ignition_conf.sysread(File.size?(ignition_name))
    ignition_conf.close
    file_size_unrounded = contents.bytesize
    if file_size_unrounded < minimum_disk_size
      file_size = minimum_disk_size - partitioner_reserved_space
    elsif (file_size_unrounded % lba_size) != 0
      file_size = lba_size * ((file_size_unrounded / lba_size) + 1)
    else
      file_size = file_size_unrounded
    end
    drive_size = file_size + partitioner_reserved_space

    # Calculated variables
    drive_sectors    = drive_size / lba_size
    gpt2_lba         = drive_sectors - 1
    arr2_lba         = drive_sectors - 33
    # This is global as gen_gpt requires it
    @last_usable_lba = drive_sectors - 34

    ## START PMBR ##
    pmbr  = ("\0".bytes) * 446         # bootloader code
    pmbr += "\x00".bytes               # status code
    pmbr += "\x00\x01\x00".bytes       # first CHS (for a protective MBR, we can just use the min value)
    pmbr += "\xee".bytes               # partition type
    pmbr += "\xfe\xff\xff".bytes       # last CHS (for a protective MBR, we can just use the max value)
    pmbr += "\x01\x00\x00\x00".bytes   # first LBA of first partition
    pmbr += [gpt2_lba].pack('L').bytes # last LBA of first partition
    pmbr += ("\x00".bytes) * 48        # other partition data
    pmbr += "\x55\xaa".bytes           # MBR signature
    ## END PMBR ##

    ## START PART ##

    # UUID format on disk according to cgpt:
    # typedef struct {
    # UINT32 Data1;
    # UINT16 Data2;
    # UINT16 Data3;
    # UINT8 Data4[8];
    # } EFI_GUID;

    # Partition Type GUID is 0FC63DAF-8483-4772-8E79-3D69D8477DE4 (Linux Filesystem)
    part1  = [0x0FC63DAF].pack('L').bytes + [0x8483].pack('S').bytes + [0x4772].pack('S').bytes + [0x8E793D69D8477DE4].pack('Q').bytes.reverse!
    # Partition GUID is 99570A8A-F826-4EB0-BA4E-9DD72D55EA13
    part1 += [0x99570A8A].pack('L').bytes + [0xF826].pack('S').bytes + [0x4EB0].pack('S').bytes + [0xBA4E9DD72D55EA13].pack('Q').bytes.reverse!
    part1 += [@first_usable_lba].pack('Q').bytes                                                                # first LBA of first partition
    part1 += [@last_usable_lba].pack('Q').bytes                                                                 # last LBA of first partition
    part1 += "\0".bytes * 8                                                                                     # partition attributes
    part1 += part_label_encoded + ("\0".bytes * (72 - part_label_encoded.length))                               # partition name (length of 72 bytes, or 36 utf16le characters)
    part_others = "\0".bytes * (arr_length - part1.length)                                                      # other partition data
    part_arr = part1 + part_others
    part_extra_space = "\0".bytes * ((@first_usable_lba * lba_size) - (pmbr_length + @gpt_length + arr_length)) # this adds a buffer so that our partition starts at sector 2048
    part_full = part_arr + part_extra_space
    ## END PART ##


    ## START GPT ##
    gpt = gen_gpt(gpt_lba, gpt2_lba, arr_lba, part_arr)
    ## END GPT ##

    ## START GPT2 ##
    gpt2 = gen_gpt(gpt2_lba, gpt_lba, arr2_lba, part_arr)
    ## END GPT2 ##

    ## START DATA ##
    if file_size_unrounded < minimum_disk_size
      data = contents.bytes + ("\x00".bytes * (file_size - contents.bytesize))
    else
      data = contents.bytes + ("\x00".bytes * (lba_size - (file_size_unrounded % lba_size)))
    end
    ## END DATA ##

    device = pmbr + gpt + part_full + data + part1 + part_others + gpt2

    File.open(config_drive, 'wb' ) do |output|
      device.each do | byte |
        output.print byte.chr
      end
    end
  end

  # The only thing calling this function should be self.create_disk
  private_class_method def self.gen_gpt(curr_lba, other_lba, arr_lba, part_arr)
    gpt_first  = "\x45\x46\x49\x20\x50\x41\x52\x54".bytes                       # GPT signature
    gpt_first += "\x00\x00\x01\x00".bytes                                       # GPT version
    gpt_first += "\x5c\x00\x00\x00".bytes                                       # GPT header size

    gpt_fakecrc = "\x00\x00\x00\x00".bytes                                      # CRC for header must be zeroed during calculation

    gpt_second  = "\x00\x00\x00\x00".bytes                                      # reserved zero bytes
    gpt_second += [curr_lba].pack('Q').bytes                                    # LBA of current table
    gpt_second += [other_lba].pack('Q').bytes                                   # LBA of backup/secondary table
    gpt_second += [@first_usable_lba].pack('Q').bytes                           # first usable lba for partitions
    gpt_second += [@last_usable_lba].pack('Q').bytes                            # last usable lba for partitions
    # gpt uuid is C89E4452-AAF1-67D0-8299-E7651D2805A8
    gpt_second += [0xC89E4452].pack('L').bytes + [0xAAF1].pack('S').bytes + [0x67D0].pack('S').bytes + [0x8299E7651D2805A8].pack('Q').bytes.reverse!
    gpt_second += [arr_lba].pack('Q').bytes                                     # LBA of this table's partition array
    gpt_second += [@gpt_max_entries].pack('L').bytes                            # max number of entries in partition array
    gpt_second += [@gpt_entrysize].pack('L').bytes                              # size (in bytes) of each entry in partition array
    gpt_second += [Zlib::crc32((part_arr).pack('C*'))].pack('L').bytes          # CRC for the partition array

    gpt_intermediate = gpt_first + gpt_fakecrc + gpt_second                     # this is used during crc32 calculation

    gpt_crc = [Zlib::crc32(gpt_intermediate.pack('C*'))].pack('L').bytes

    gpt_end = ("\x00".bytes) * (@gpt_length - gpt_intermediate.length)          # padding to finish LBA

    # Return finished gpt
    gpt_first + gpt_crc + gpt_second + gpt_end
  end
end
