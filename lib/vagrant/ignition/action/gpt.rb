#!/usr/bin/ruby
require 'zlib'

def create_disk(ignition_name, config_drive)
minimum_disk_size = 1536000 # ~1.5M; there are issues with udev not registering the device if it is less than this...

ignition_conf = File.open(ignition_name, "r")
contents = ignition_conf.sysread(File.size?(ignition_name))
ignition_conf.close
file_size_unrounded = contents.bytesize
if file_size_unrounded < minimum_disk_size
		file_size = minimum_disk_size - ((2048+33)*512)
elsif (file_size_unrounded%512) != 0
		file_size = 512 * ((file_size_unrounded / 512) + 1)
else
		file_size = file_size_unrounded
end
drive_size = file_size + ((2048+33)*512)

## START PMBR ##
pmbr_boot_code = ("\0".bytes) * 446
pmbr_status = "\x00".bytes
pmbr_fchs = "\x00\x01\x00".bytes
pmbr_type = "\xee".bytes
pmbr_lchs = "\xfe\xff\xff".bytes
pmbr_flba = "\x01\x00\x00\x00".bytes
pmbr_llba = [(drive_size/512)-1].pack('L').bytes
pmbr_extra_parts = ("\x00".bytes) * 48
pmbr_sig = "\x55\xaa".bytes
pmbr = pmbr_boot_code + pmbr_status + pmbr_fchs + pmbr_type + pmbr_lchs + pmbr_flba + pmbr_llba + pmbr_extra_parts + pmbr_sig
## END PMBR ##

## START PART ##

# UUID format on disk according to cgpt:
# typedef struct {
# UINT32 Data1;
# UINT16 Data2;
# UINT16 Data3;
# UINT8 Data4[8];
# } EFI_GUID;

# typeguid is AF3DC60F-8384-7247-8E79-3D69D8477DE4 (Linux Filesystem)
part_typeguid = [0x0FC63DAF].pack('L').bytes + [0x8483].pack('S').bytes + [0x4772].pack('S').bytes + [0x8E793D69D8477DE4].pack('Q').bytes.reverse!
# partguid is 99570A8A-F826-4EB0-BA4E-9DD72D55EA13
part_partguid = [0x99570A8A].pack('L').bytes + [0xF826].pack('S').bytes + [0x4EB0].pack('S').bytes + [0xBA4E9DD72D55EA13].pack('Q').bytes.reverse!
part_flba = [2048].pack('Q').bytes # most linux gpt utils start the first partition at sector 2048, so we'll just do that
part_llba = [(drive_size/512)-34].pack('Q').bytes
part_attr = "\0".bytes * 8
part_name = "Ignition Config Drive".encode("utf-16le").bytes + ("\0".bytes * 30)
part_other = "\0".bytes * 16256
part = part_typeguid + part_partguid + part_flba + part_llba + part_attr + part_name + part_other
part_extra_space = "\0".bytes * 2014 * 512 # this adds a buffer so that our partition starts at sector 2048
part_full = part + part_extra_space
## END PART ##


## START GPT ##
gpt_sig = "\x45\x46\x49\x20\x50\x41\x52\x54".bytes
gpt_rev = "\x00\x00\x01\x00".bytes
gpt_hsize = "\x5c\x00\x00\x00".bytes
gpt_first = gpt_sig + gpt_rev + gpt_hsize

gpt_fakecrc = "\x00\x00\x00\x00".bytes

gpt_quadempty = "\x00\x00\x00\x00".bytes
gpt_clba = [1].pack('Q').bytes
gpt_blba = [(drive_size/512)-1].pack('Q').bytes
gpt_flba = [2048].pack('Q').bytes
gpt_llba = [(drive_size/512)-34].pack('Q').bytes
# gpt uuid is C89E4452-AAF1-67D0-8299-E7651D2805A8
gpt_uuid = [0xC89E4452].pack('L').bytes + [0xAAF1].pack('S').bytes + [0x67D0].pack('S').bytes + [0x8299E7651D2805A8].pack('Q').bytes.reverse!
gpt_arrloc = [2].pack('Q').bytes
gpt_entries = [128].pack('L').bytes
gpt_entrysize = [128].pack('L').bytes
gpt_arrcrc = [Zlib::crc32(part.pack('C*'))].pack('L').bytes
gpt_end = ("\x00".bytes) * 420

gpt_second = gpt_quadempty + gpt_clba + gpt_blba + gpt_flba + gpt_llba + gpt_uuid + gpt_arrloc + gpt_entries + gpt_entrysize + gpt_arrcrc

gpt_intermediate = gpt_first + gpt_fakecrc + gpt_second

gpt_crc = [Zlib::crc32(gpt_intermediate.pack('C*'))].pack('L').bytes

gpt = gpt_first + gpt_crc + gpt_second + gpt_end
## END GPT ##

## START GPT2 ##
gpt2_arrloc = [(drive_size/512)-33].pack('Q').bytes
gpt2_first = gpt_sig + gpt_rev + gpt_hsize
gpt2_second = gpt_quadempty + gpt_blba + gpt_clba + gpt_flba + gpt_llba + gpt_uuid + gpt2_arrloc + gpt_entries + gpt_entrysize + gpt_arrcrc
gpt2_intermediate = gpt2_first + gpt_fakecrc + gpt2_second

gpt2_crc = [Zlib::crc32(gpt2_intermediate.pack('C*'))].pack('L').bytes

gpt2 = gpt2_first + gpt2_crc + gpt2_second + gpt_end
## END GPT2 ##

## START DATA ##
if file_size_unrounded < minimum_disk_size
		data = contents.bytes + ("\x00".bytes * (file_size - contents.bytesize))
else
		data = contents.bytes + ("\x00".bytes * (512 - (file_size_unrounded % 512)))
end
## END DATA ##

device = pmbr + gpt + part_full + data + part + gpt2

File.open(config_drive, 'wb' ) do |output|
     device.each do | byte |
          output.print byte.chr
     end
end

end # end method
