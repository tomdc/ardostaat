#!/usr/bin/perl -w

use strict;
use RRDs;
use Data::Dumper;

#
# room1:
# room2:
# room3:
#

my $prefix="/mnt/ramdisk/html";

my $room=$ARGV[0];

my @rooms=( "room0", "room1" , "room2", "room3" );

my %periods = (
		"hour"	=>	{ "time" => "-4h", "desc" => "1 PDP" },
		"day"		=>	{ "time" => "-2d", "desc" => "1 PDP" },
		"week"	=>	{ "time" => "-8d", "desc" => "2 hour averages" },
		"month"	=>	{ "time" => "-35d", "desc" => "2 hour averages" },
		"year"	=>	{ "time" => "-1y", "desc" => "2 hour averages" },
		"5years" => { "time" => "-5y", "desc" => "1 day averages" },
);

foreach my $r (@rooms) {
	for my $p ( keys %periods ) {
		graph($p, $r);
	}
}

sub graph {
	my $period=shift;
	my $room=shift;

	if ( $period eq "hour" ) {
		RRDs::graph ("$prefix/$room\_$period.png", "--vertical-label", "Temperature C / Relative Humidity %","-t" , "$period view -- $periods{$period}{desc}", "--end", "now", "--start", "$periods{$period}{time}", "--height" , "300", "--width" , "520", "-l" ,"0",
			"DEF:temp=rrd/$room.rrd:temp:AVERAGE",
			"DEF:humi=rrd/$room.rrd:humi:AVERAGE",
			"AREA:humi#7FFFD4:Humidity",
	    "VDEF:last_temp=temp,LAST",
	    "VDEF:max_temp=temp,MAXIMUM",
	    "VDEF:avg_temp=temp,AVERAGE",
	    "VDEF:min_temp=temp,MINIMUM",
	    "VDEF:last_humi=humi,LAST",
	    "VDEF:max_humi=humi,MAXIMUM",
	    "VDEF:avg_humi=humi,AVERAGE",
	    "VDEF:min_humi=humi,MINIMUM",
			'GPRINT:last_humi:   Last\: %4.2lf',
			'GPRINT:avg_humi:Average\: %4.2lf',
			'GPRINT:max_humi:Max\: %4.2lf',
			'GPRINT:min_humi:Min\: %4.2lf\n',
			"LINE2:temp#FF0000:Temperature",
			'GPRINT:last_temp:Last\: %4.2lf',
			'GPRINT:avg_temp:Average\: %4.2lf',
			'GPRINT:max_temp:Max\: %4.2lf',
			'GPRINT:min_temp:Min\: %4.2lf\n',
		);
	}
	else {
		RRDs::graph ("$prefix/$room\_$period.png", "--vertical-label", "Temperature C / Relative Humidity %","-t" , "$period view -- $periods{$period}{desc}", "--end", "now", "--start", "$periods{$period}{time}", "--height" , "300", "--width" , "520",  "-l" ,"0",
			"DEF:temp=rrd/$room.rrd:temp:AVERAGE",
			"DEF:humi=rrd/$room.rrd:humi:AVERAGE",
			"AREA:humi#7FFFD4:Humidity",
	    "VDEF:last_temp=temp,LAST",
	    "VDEF:max_temp=temp,MAXIMUM",
	    "VDEF:avg_temp=temp,AVERAGE",
	    "VDEF:min_temp=temp,MINIMUM",
	    "VDEF:last_humi=humi,LAST",
	    "VDEF:max_humi=humi,MAXIMUM",
	    "VDEF:avg_humi=humi,AVERAGE",
	    "VDEF:min_humi=humi,MINIMUM",
			'GPRINT:avg_humi:   Average\: %4.2lf',
			'GPRINT:max_humi:Max\: %4.2lf',
			'GPRINT:min_humi:Min\: %4.2lf\n',
			"LINE2:temp#FF0000:Temperature",
			'GPRINT:avg_temp:Average\: %4.2lf',
			'GPRINT:max_temp:Max\: %4.2lf',
			'GPRINT:min_temp:Min\: %4.2lf\n',
		);


}

	my $ERR=RRDs::error;
	die "ERROR while creating rrd/$room.rrd: $ERR\n" if $ERR;
}
