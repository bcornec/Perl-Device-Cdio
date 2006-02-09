package Device::Cdio::Device;
require 5.8.7;
#
#    $Id$
#
#    Copyright (C) 2006 Rocky Bernstein <rocky@panix.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# See the bottom of this file for the POD documentation.  Search for
# the string '=head'.

=pod

=head1 NAME

Cdio:Device handles disc and device aspects of Cdio.

=cut

use strict;
use Exporter;
use perlcdio;
use Device::Cdio::Util qw( _check_arg_count _extra_args _rearrange );
use Device::Cdio qw(convert_drive_cap_read convert_drive_cap_write 
		    convert_drive_cap_misc );
use Device::Cdio::Track;

@Device::Cdio::Device::ISA = qw( CGI );
$Device::Cdio::Device::VERSION = '0.01';
@Device::Cdio::Device::EXPORT = qw( close open new );

=pod 

=head1 METHODS

=cut

=pod 

=head2 new

new(source, driver_id, access_mode)->track_object

Create a new Track object. Either driver_id or source can be
undef. Probably best to not to give anaccess_mode too, unless you know
what you are doing.

=cut 
sub new {

  my($class,@p) = @_;

  my($source, $driver_id, $access_mode, @args) = 
      _rearrange(['SOURCE', 'DRIVER_ID', 'ACCESS_MODE'], @p);

  return undef if _extra_args(@args);

  my $self = {};
  $self->{cd} = undef;

  bless ($self, $class);

  $self->open($source, $driver_id,  $access_mode)
      if defined($source) || defined($driver_id);

  return $self;
}

=pod 

=head2 audio_pause

audio_pause(cdio)->status
Pause playing CD through analog output.
The device status is returned.

=cut

sub audio_pause {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::audio_pause($self->{cd});
}

=pod

=head2 audio_play_lsn

audio_play_lsn(cdio, start_lsn, end_lsn)->status
        
Playing CD through analog output at the given lsn to the ending lsn
The device status is returned.

=cut 

sub audio_play_lsn {
    my($self,@p) = @_;
    my($start_lsn, $end_lsn, @args) = 
	_rearrange(['START_LSN', 'END_LSN'], @p);
    return $perlcdio::BAD_PARAMETER if _extra_args(@args);
    return perlcdio::audio_play_lsn($self->{cd}, $start_lsn, $end_lsn);
}

=pod 

=head2 audio_resume

audio_resume(cdio)->status

Resume playing an audio CD through the analog interface.
The device status is returned.

=cut

sub audio_resume {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::audio_resume($self->{cd});
}

=pod

=head2 audio_stop

audio_stop(cdio)->status

Stop playing an audio CD through the analog interface.  The device
status is returned.

=cut

sub audio_stop {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::audio_stop($self->{cd});
}

=pod

=head2 close

close()->bool

Free resources associated with cdio.  Call this when done using using
CD reading/control operations for the current device.

=cut

sub close {
    my($self,@p) = @_;
    return 0 if !_check_arg_count($#_, 0);
    if (defined($self->{cd})) {
	perlcdio::close($self->{cd});
    } else {
	print "***No object to close\n";
        $self->{cd} = undef;
	return 0;
    }
    return 1;
}

=pod

=head2 eject_media

eject_media()->drc
Eject media in CD drive if there is a routine to do so.
status is returned.

=cut

sub eject_media {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    my $drc = perlcdio::eject_media($self->{cd});
    $self->{cd} = undef;
    return $drc;
}

=pod

=head2 get_arg

get_arg(key)->string

=cut

sub  get_arg {
    my($self,@p) = @_;
    my($key, @args) = 	_rearrange(['KEY'], @p);
    return undef if _extra_args(@args);
    return perlcdio::get_arg($self->{cd}, $key);
}

=pod

=head2 get_default_device_driver

get_default_device_driver( driver_id=$perlcdio::DRIVER_DEVICE)->str

Get the default CD device.  If we haven't initialized a specific
device driver, then find a suitable one and return the default device
for that.  In some situations of drivers or OS's we can't find a CD
device if there is no media in it and it is possible for this routine
to return undef even though there may be a hardware CD-ROM.

=cut

sub get_default_device_driver {
    my($self,@p) = @_;
    my($driver_id, @args) = _rearrange(['DRIVER_ID'], @p);
    return undef if _extra_args(@args);
    $driver_id = $perlcdio::DRIVER_DEVICE if !defined($driver_id);
    return perlcdio::get_default_device_driver($driver_id);
}

=pod

=head2 get_device

get_device()->str

Get the default CD device.
If we haven't initialized a specific device driver), 
then find a suitable one and return the default device for that.
In some situations of drivers or OS's we can't find a CD device if
there is no media in it and it is possible for this routine to return
undef even though there may be a hardware CD-ROM.

=cut

sub get_device {
    my($self,@p) = @_;
    return undef if !_check_arg_count($#_, 0);
    return perlcdio::get_device($self->{cd});
}

=pod

=head2 get_disc_last_lsn

get_disc_last_lsn(self)->int

Get the LSN of the end of the CD. $perlcdio::INVALID_LSN is
returned if there was an error.

=cut

sub get_disc_last_lsn {
    my($self,@p) = @_;
    return undef if !_check_arg_count($#_, 0);
    return perlcdio::get_disc_last_lsn($self->{cd});
}

=pod

=head2 get_disc_mode

get_disc_mode() -> str

Get disc mode - the kind of CD: CD-DA, CD-ROM mode 1, CD-MIXED, etc.
that we've got. The notion of 'CD' is extended a little to include
DVD's.

=cut 

sub get_disc_mode {
    my($self,@p) = @_;
    return perlcdio::get_disc_mode($self->{cd});
}

=pod

=head2 get_drive_cap

get_drive_cap()->(read_cap, write_cap, misc_cap)
        
Get drive capabilities of device.
       
In some situations of drivers or OS's we can't find a CD
device if there is no media in it. In this situation
capabilities will show up as empty even though there is a
hardware CD-ROM.  

=cut

sub get_drive_cap {
    my($self,@p) = @_;
    return (undef, undef, undef) if !_check_arg_count($#_, 0);
    my ($b_read_cap, $b_write_cap, $b_misc_cap) = 
	perlcdio::get_drive_cap($self->{cd});
    return (convert_drive_cap_read($b_read_cap),
	    convert_drive_cap_write($b_write_cap),
	    convert_drive_cap_misc($b_misc_cap));
}

=pod

=head2 get_drive_cap_dev

get_drive_cap_dev(device=undef)->(read_cap, write_cap, misc_cap)
       
Get drive capabilities of device.
       
In some situations of drivers or OS's we can't find a CD
device if there is no media in it. In this situation
capabilities will show up as empty even though there is a
hardware CD-ROM.

=cut

### FIXME: combine into above by testing on the type of device.
sub get_drive_cap_dev {
    my($self,@p) = @_;
    my($device, @args) = _rearrange(['DEVICE'], @p);
    return (undef, undef, undef) if _extra_args(@args);

    my ($b_read_cap, $b_write_cap, $b_misc_cap) = 
	perlcdio::get_drive_cap_dev($device);
    return (convert_drive_cap_read($b_read_cap),
	    convert_drive_cap_write($b_write_cap),
	    convert_drive_cap_misc($b_misc_cap));
}

=pod

=head2 get_driver_name

get_driver_name()-> string

return a string containing the name of the driver in use.
undef is returned if there's an error.

=cut

sub get_driver_name {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::get_driver_name($self->{cd});
}

=pod

=head2 get_driver_id

get_driver_id()-> int

=cut

sub get_driver_id {
    my($self, @p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::get_driver_id($self->{cd});
}

=pod

=head2 get_first_track

get_first_track()->Track

return a Track object of the first track. $perlcdio::INVALID_TRACK
or $perlcdio::BAD_PARAMETER is returned if there was a problem.

Return the driver id of the driver in use.
if object has not been initialized or is None,
return $perlcdio::DRIVER_UNKNOWN.

=cut

sub get_first_track {
    my($self, @p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return Device::Cdio::Track->new(-device=>$self->{cd}, 
				    -track=>perlcdio::get_first_track_num($self->{cd}));
}

=pod

=head2 get_hwinfo

get_hwinfo()->[vendor, model, release, drc]

Get the CD-ROM hardware info via a SCSI MMC INQUIRY command.
An exception is raised if we had an error. 

=cut

sub get_hwinfo {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    # There's a bug I don't understand where p_cdio gets returned
    # and it shouldn't. So we just ignore that below.
    my (undef, $vendor, $model, $release, $drc) = 
	perlcdio::get_hwinfo($self->{cd});
    return ($vendor, $model, $release, $drc);
}

=pod

=head2 get_joliet_level

get_joliet_level()->int
       
Return the Joliet level recognized for cdio.
This only makes sense for something that has an ISO-9660
filesystem.

=cut

sub get_joliet_level {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::get_joliet_level($self->{cd});
}

=pod

=head2 get_last_session

get_last_session(self) -> (track_lsn, drc)

Get the LSN of the first track of the last session of on the CD.

=cut

sub get_last_session {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::get_last_session($self->{cd});
}

=pod

=head2 get_last_track

get_last_track(self)->Track

return a Track object of the last track. $perlcdio::INVALID_TRACK
or $perlcdio::BAD_PARAMETER is returned if there was a problem.

=cut

sub get_last_track {
    my($self, @p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return Device::Cdio::Track->new(-device=>$self->{cd},
				    -track=>perlcdio::get_last_track_num($self->{cd}));
}

=pod

=head2 get_media_changed

get_media_changed() -> int

Find out if media has changed since the last call.
Return 1 if media has changed since last call, 0 if not.
A negative number indicates the driver status error.

=cut

sub get_media_changed {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::get_media_changed($self->{cd});
}

=pod

=head2 get_num_tracks

get_num_tracks()->int

Return the number of tracks on the CD. 
perlcdio::INVALID_TRACK is raised on error.

=cut

sub get_num_tracks {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return  perlcdio::get_num_tracks($self->{cd});
}

=pod

=head2 get_track

get_track(track_num)->track

Set a new track object of the current disc for the given track number.

=cut 

sub get_track {
    my($self,@p) = @_;
    my($track_num, @args) = _rearrange(['TRACK'], @p);
    return undef if _extra_args(@args);
    return Device::Cdio::Track->new(-device=>$self->{cd}, -track=>$track_num);
}

=pod

=head2 get_track_for_lsn

get_track_for_lsn(LSN)->Track

Find the track which contains LSN.  undef is returned if the lsn
outside of the CD or if there was some error.

If the LSN is before the pregap of the first track, A track object
with a 0 track is returned.  Otherwise we return the track that spans
the lsn.

=cut

sub get_track_for_lsn {
    my($self,@p) = @_;
    my($lsn_num, @args) = _rearrange(['LSN'], @p);
    return undef if _extra_args(@args);
    my $track = perlcdio::get_last_track_num($self->{cd});
    return undef if ($track == $perlcdio::INVALID_TRACK);
    return Device::Cdio::Track->new(-device=>$self->{cd}, -track=>$track);
}

=pod

=head2 have_ATAPI

have_ATAPI()->bool

return 1 if CD-ROM understand ATAPI commands.

=cut

sub have_ATAPI {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::have_ATAPI($self->{cd});
}

=pod

=head2 lseek

lseek(offset, whence)->int

Reposition read offset. Similar to (if not the same as) libc's fseek()

offset is the amount to seek and whence is like corresponding
parameter in libc's lseek, e.g.  it should be SEEK_SET or SEEK_END.

the offset is returned or -1 on error.

=cut

sub lseek {
    my($self,@p) = @_;
    my($offset, $whence, @args) = _rearrange(['OFFSET', 'WHENCE'], @p);
    return -1 if _extra_args(@args);
    return perlcdio::lseek($self->{cd}, $offset, $whence);
}

=pod

=head2 open

open(source=undef, driver_id=libcdio.DRIVER_UNKNOWN,
    access_mode=undef)

Sets up to read from place specified by source, driver_id and access
mode. This should be called before using any other routine except
those that act on a CD-ROM drive by name. It is implicitly called when
a new is done specifying a source or driver id.

If undef is given as the source, we'll use the default driver device.
If undef is given as the driver_id, we'll find a suitable device
driver.  Device is opened so that subsequent operations can be
performed. 

=cut

sub open {
    my($self,@p) = @_;
    my($source, $driver_id, $access_mode) = 
	_rearrange(['SOURCE', 'DRIVER_ID', 'ACCESS_MODE'], @p);
    
    $driver_id = $perlcdio::DRIVER_UNKNOWN 
	if !defined($driver_id);
    
    $self->close() if defined($self->{cd});
    $self->{cd} = perlcdio::open_cd($source, $driver_id, $access_mode);
}

=pod

=head2 set_blocksize

set_blocksize(blocksize)->status

Set the blocksize for subsequent reads.  The operation status code is
returned.

=cut 

sub set_blocksize {
    my($self,@p) = @_;
    my($blocksize, @args) = _rearrange(['BLOCKSIZE'], @p);
    return $perlcdio::BAD_PARAMETER if _extra_args(@args);
    return perlcdio::set_blocksize($self->{cd}, $blocksize);
}

=pod

=head2 set_speed

set_speed(speed)->drc

The operation status code is returned.

=cut 

sub set_speed {
    my($self,@p) = @_;
    my($speed, @args) =  _rearrange(['SPEED'], @p);
    return $perlcdio::BAD_PARAMETER if _extra_args(@args);
    return perlcdio::set_speed($self->{cd}, $speed);
}

=pod

=head2 set_track

set_track(track_num)

Set a new track number for the given track number.

=cut 

sub set_track {
    my($self,@p) = @_;
    my($track_num, @args) = _rearrange(['TRACK'], @p);
    return undef if _extra_args(@args);
    $self->{track} = $track_num;
    return $self;
}

1;

__END__

    def read(size):
        """
        read(size)->[size, data]
        
        Reads the next size bytes.
        Similar to (if not the same as) libc's read()
        
        The number of bytes read and the data is returned. 
        A DeviceError exception may be raised.
        """
        size, data = $perlcdio::read_cd($self->{cd}, size)
        __possibly_raise_exception__(size)
        return [size, data]
    
    def read_sectors(lsn, read_mode, blocks=1):
        """
        read_sectors(lsn, read_mode, blocks=1)->[blocks, data]
        Reads a number of sectors (AKA blocks).
        
        lsn is sector to read, bytes is the number of bytes.
        
        If read_mode is $perlcdio::MODE_AUDIO, the return buffer size will be
        truncated to multiple of $perlcdio::CDIO_FRAMESIZE_RAW i_blocks bytes.
        
        If read_mode is $perlcdio::MODE_DATA, buffer will be truncated to a
        multiple of $perlcdio::ISO_BLOCKSIZE, $perlcdio::M1RAW_SECTOR_SIZE or
        $perlcdio::M2F2_SECTOR_SIZE bytes depending on what mode the data is in.

        If read_mode is $perlcdio::MODE_M2F1, buffer will be truncated to a 
        multiple of $perlcdio::M2RAW_SECTOR_SIZE bytes.
        
        If read_mode is $perlcdio::MODE_M2F2, the return buffer size will be
        truncated to a multiple of $perlcdio::CD_FRAMESIZE bytes.
        
        The number of bytes read and the data is returned. 
        A DeviceError exception may be raised.
        """
        try:
            blocksize = read_mode2blocksize[read_mode]
            size = blocks * blocksize
        except KeyError:
            raise DriverBadParameterError ('Bad read mode %d' % read_mode)
        size, data = $perlcdio::read_sectors($self->{cd}, size, lsn, read_mode)
        if size < 0:
            __possibly_raise_exception__(size)
        blocks = size / blocksize
        return [blocks, data]

    def read_data_blocks(lsn, blocks=1):
        """
        read_data_blocks(blocks, lsn, blocks=1)->[size, data]
        
        Reads a number of data sectors (AKA blocks).
        
        lsn is sector to read, bytes is the number of bytes.
        A DeviceError exception may be raised.
        """
        size = $perlcdio::ISO_BLOCKSIZE*blocks
        size, data = $perlcdio::read_data_bytes($self->{cd}, size, lsn,
                                            $perlcdio::ISO_BLOCKSIZE)
        if size < 0:
             __possibly_raise_exception__(size)
        return [size, data]
    
1;

__END__

=pod

=head1 SEE ALSO

L<Device::Cdio> for the top-level routines and L<Device::Cdio::Track>
for track objects.

L<perlcdio> is the lower-level interface to libcdio.

L<http://www.gnu.org/software/libcdio> has documentation on
libcdio including the a manual and the API via doxygen.

=head1 AUTHORS

Rocky Bernstein C<< <rocky at panix.com> >>.

=head1 COPYRIGHT

Copyright (C) 2006 Rocky Bernstein <rocky@panix.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
