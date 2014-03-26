#!/usr/bin/perl -w

# parse every 5mins

use strict;
use Data::Dumper;
use RRDs;

#
# to be replaced by a wget -T 4
my $rv=`wget http://192.168.1.30 2>&1 >> /dev/null`;

open( INDEX, "index.html");
my @page=<INDEX>;
close INDEX;

$rv=`rm index.html*`;

# to match:
# room0 temp:23.50 humi:38.00<br>

foreach my $line (@page) {
	chomp $line;
	my ($room, $temp, $humi);
	if ( $line =~ /(\S+)\s+temp:(\d+\.\d+)\s+humi:(\d+\.\d+)<br>/ ) {
		$room=$1;
		$temp=$2;
		$humi=$3;

		if ( -e "rrd/$room.rrd" ) {
			#updatestuff
			update_rrd($room, $temp ,$humi);
		}
		else {
			# create rrd
			create_rrd($room);
			# updatestuff
		}
	}
}

sub update_rrd {
	my $r=shift;
	my $t=shift;
	my $h=shift;
	#print "Updating $r.rrd with temp:$t and humi:$h\n";
	RRDs::update("rrd/$r.rrd","N:$t:$h");
	my $ERR=RRDs::error;
	die "ERROR while updating mydemo.rrd: $ERR\n" if $ERR;
}

sub create_rrd{
	my $file=shift;
	print "Creating rrd/$file\.rrd ...\n";
	RRDs::create ("rrd/$file.rrd", "--step", "300" ,
		"DS:temp:GAUGE:600:-50:200",
		"DS:humi:GAUGE:600:-50:200",
		"RRA:LAST:0.5:1:12",						# 1 pdp for 6days
		"RRA:AVERAGE:0.5:1:17280",					# 1 pdp for 6days
		"RRA:MIN:0.5:1:17280",
		"RRA:MAX:0.5:1:17280",
		"RRA:AVERAGE:0.5:24:4800",					# 2 hours for 1 years
		"RRA:MIN:0.5:24:4800",
		"RRA:MAX:0.5:24:4800",
		"RRA:AVERAGE:0.5:288:1825",					# 1 day for 5 years
	);
	my $ERR=RRDs::error;
 	die "ERROR while creating mydemo.rrd: $ERR\n" if $ERR;
}
