#!/usr/bin/perl

eval 'exec /usr/bin/perl -S $0 ${1+"$@"}'
	if $running_under_some_shell;

my $progname = $0;

my $debug	= 0;
my $trace	= 0;
my $verbose	= 0;
my @infiles	= ( );
my $infile	= "/dev/stdin";
my $outfile	= "/dev/stdout";

while ($ARGV[0]=~/^-/) {
	$_ = shift;
	last if /^--$/;
	if (/^-n/) { $nflag++;	     next; }
	if (/^-d/) { $debug	= 1; next; }
	if (/^-t/) { $trace	= 1; next; }
	if (/^-v/) { $verbose	= 1; next; }
	if (/^-f(.*)/) { if ($1) { push @infiles, $1; } else { push @infiles, shift; } next; }
	if (/^-o(.*)/) { if ($1) { $outfile = $1; } else { $outfile = shift; } next; }
	if (/^--help/) {
		print<<EOF;
Usage:
  $0 [-d] [-t] [-v] [ [-f] infile [ [-o] outfile ] ]
     -d - turn on debug mode
     -t - turn on trace mode (lost of info)
     -v - turn on verbose mode (lots of info)
     [-f] infile  -  input file (default: $infile)
     [-o] outfile - output file (default: $outfile)
     --help - print usage information
     --version - print version information
     --copying - print copying permissions
EOF
		exit 0;
	}
	if (/^--version/) {
		print<<'EOF';
$RCSfile$ $Name$($Revision$) $Date$
Copyright (c) 2008, 2009, 2010, 2011  Monavacon Limited.
Copyright (c) 2002, 2003, 2004, 2005, 2006, 2007  OpenSS7 Corporation.
Copyright (c) 1996, 1997, 1998, 1999, 2000, 2001  Brian Bidulock.
All Rights Reserved.  Distributed my OpenSS7 Corporation under AGPL
Version 3, included here by reference.  See `snmpcheck --copying' for
copying permissions.
EOF
	}
	if (/^--copying/) {
		print<<'EOF';
-----------------------------------------------------------------------------
# @(#) $RCSfile$ $Name$($Revision$) $Date$
-----------------------------------------------------------------------------
Copyright (c) 2008-2011  Monavacon Limited <http://www.monavacon.com/>
Copyright (c) 2001-2008  OpenSS7 Corporation <http://www.openss7.com/>
Copyright (c) 1997-2001  Brian F. G. Bidulock <bidulock@openss7.org>

All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation; version 3 of the License.
This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for more
details.

You should have received a copy of the GNU Affero General Public License along
with this program.  If not, see <http://www.gnu.org/licenses/>, or write to
the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
-----------------------------------------------------------------------------
U.S. GOVERNMENT RESTRICTED RIGHTS.  If you are licensing this Software on
behalf of the U.S. Government ("Government"), the following provisions apply
to you.  If the Software is supplied by the Department of Defense ("DoD"), it
is classified as "Commercial Computer Software" under paragraph 252.227-7014
of the DoD Supplement to the Federal Acquisition Regulations ("DFARS") (or any
successor regulations) and the Government is acquiring only the license rights
granted herein (the license rights customarily provided to non-Government
users).  If the Software is supplied to any unit or agency of the Government
other than DoD, it is classified as "Restricted Computer Software" and the
Government's rights in the Software are defined in paragraph 52.227-19 of the
Federal Acquisition Regulations ("FAR") (or any successor regulations) or, in
the cases of NASA, in paragraph 18.52.227-86 of the NASA Supplement to the FAR
(or any successor regulations).
-----------------------------------------------------------------------------
Commercial licensing and support of this software is available from OpenSS7
Corporation at a fee.  See http://www.openss7.com/
-----------------------------------------------------------------------------
EOF
	}
	print STDERR <<EOF;
I: $0 Usage:
I:   $0 [-d] [-t] [-v] [ [-f] infile [ [-o] outfile ] ]
I:      -d - turn on debug mode
I:      -t - turn on trace mode (lots of info)
I:      -v - turn on verbose mode (lots of info)
I:      -x - report crossreferences in output
I:      [-f] infile  -  input file (default stdin)
I:      [-o] outfile - output file (default stdout)
I:      --help - print usage information
I:      --version - print version information
I:      --copying - print copying permissions
EOF
	die "E: I don't recognize this switch: $_\n";
}

foreach my $file (@ARGV) {
	push @infiles, $file;
}

$printit++ unless $nflag;

#$\ = "\n";	# add new-line to print
#$* = 0;	$ do singleline matching
undef $/;	# read entire file

use Carp;

use Net::Pcap qw(:functions);
use Tk;
use Tk::Xrm;
use Tk::Event;
use Tk::Trace;
require Tk::Toplevel;
require Tk::Adjuster;
require Tk::Dialog;
require Tk::HList;
require Tk::ROText;
require Tk::NoteBook;
require Tk::Pane;
require Tk::Balloon;
require Tk::DragDrop;
require Tk::DropSite;
require Tk::TableMatrix;
require Tk::TableMatrix::Spreadsheet;
require Tk::Frame;
require Tk::TFrame;

use Data::Dumper;
use Date::Parse;
use XML::Simple;
use XML::SAX;
use XML::SAX::Base;
#use XML::SAX::ParseFactory;

use Time::HiRes qw(gettimeofday);

my $canvas;
my $mycanvas;
my $top;
my $mw;
my $begtime;
my $endtime;

my %large_networks = (
	254=>['AT&T',	    'AT&T Communications'],
	253=>['Sprint',	    'US Sprint'],
	252=>['BellSouth',  'BellSouth Services'],
	251=>['Pacific',    'Pacific Bell'],
	250=>['Ameritech',  'Ameritech'],
	249=>['SWB',	    'Southwestern Bell Telephone'],
	248=>['Bell',	    'Bell Tri-Co Services'],
	247=>['Nynex',	    'Nynex Service Co.'],
	246=>['BA',	    'Bell Atlantic'],
	245=>['Canada',	    'Telecom Canada'],
	244=>['MCI',	    'MCI Telecommunications Group'],
	243=>['SNET',	    'Southern New England Telephone'],
	242=>['Allnet',	    'Allnet Communications Services Inc.'],
	241=>['DCA',	    'Defense Comm Agency'],
	240=>['GTE',	    'GTE Service Corporation/Telephone Operations'],
	239=>['United',	    'United Telephone Sys'],
	238=>['Independent','Independent Telecommunications Network'],
	237=>['C&W',	    'Cable & Wireless'],
	236=>['CNCP',	    'CNCP Telecommunications'],
	235=>['Comtel',	    'Comtel'],
	234=>['Alltel',	    'Alltel'],
	233=>['Rochester',  'Rochester Telephone'],
	232=>['Century',    'Century Telephone Enterprises, Inc.'],
	231=>['AT&T',	    'AT&T (VSN)'],
	230=>['Centel',	    'Centel'],
	229=>['Test',	    'Test Code'],
	228=>['Pacific',    'Pacific Telecom'],
	227=>['NACN',	    'North America Cellular Network'],
	226=>['Cantel',	    'Cantel'],
);
my %small_networks = (
	1=>{
		 1=>['Puerto Rico',	'Puerto Rico Telephone Company'],
		 2=>['Cincinnati',	'Cincinnati Bell'],
		 3=>['LDS',		'LDS Metromedia Ltd'],
		 4=>['Schneider ',	'Schneider Communications'],
		 5=>['Microtel',	'Microtel Inc'],
		 6=>['ACC',		'ACC Long Distance Corp'],
		 7=>['SouthernNet',	'SouthernNet'],
		 8=>['Teleconnect',	'Teleconnect Co'],
		 9=>['Telepshere',	'Telesphere Network'],
		10=>['MidAmerican',	'MidAmerican'],
		11=>['LDUSA',		'Long Distance USA'],
		12=>['RCI',		'RCI Corporation'],
		13=>['Phoenix',		'Phoenix Network'],
		14=>['Teledial',	'Teledial America'],
		15=>['USTS',		'U.S. Transmission Systems'],
		16=>['Litel',		'Litel Telecommunication Corp'],
		17=>['Chadwick',	'Chadwick Telephone'],
		18=>['LDS',		'Long Distance Service Inc'],
		19=>['WITS',		'Washington Interagency Telecommunications Service'],
		20=>['PBS',		'Phone Base Systems, Inc'],
		21=>['General',		'General Communication Incorporated'],
		22=>['CTI',		'CTI Telecommunications Incorporated'],
		23=>['SouthTel',	'SouthTel'],
		24=>['Roseville',	'Roseville Telephone Company'],
		25=>['TCL',		'TelaMarketing Corporation of Louisiana'],
		26=>['LDDS',		'LDDS'],
		27=>['Capital',		'Capital Telecommunications, Inc.'],
		28=>['Transtel',	'Transtel Corporation'],
		29=>['ComSystem',	'ComSystem'],
		30=>['Mid Altantic',	'Mid Altantic'],
		33=>['NTC',		'NTC Inc.'],
		34=>['NDC',		'National Data Corporation'],
		35=>['FTC',		'FTC Communications, Inc.'],
		36=>['Lincoln',		'Lincoln Telephone Company'],
		37=>['Alascom',		'Alascom'],
		38=>['Motorola',	'Motorola, Inc.'],
		39=>['West Coast',	'West Coast Telecommunications'],
		40=>['LDS',		'LDS'],
		41=>['EdTel',		'Ed Tel'],
		42=>['NPT',		'North Pittsburg Telephone'],
		43=>['Rock Hill',	'Rock Hill Telephone'],
		44=>['Teleglobe',	'Teleglobe Canada'],
		45=>['Jamaica',		'Jamaica Telephone Company Limited'],
		46=>['Sugar Land',	'Sugar Land Telephone'],
		47=>['Lakedale',	'Lakedale Telephone'],
		48=>['Chillicothe ',	'Chillicothe Telephone Company'],
		49=>['NSTC',		'North State Telephone Company'],
		50=>['PSTC',		'Public Service Telephone Company'],
		51=>['Cincinnati',	'Cincinnati Bell Long Distance'],
		52=>['NTE',		'National Telephone Exchange'],
		53=>['Lake States',	'Lake States Long Distance'],
		54=>['NTF',		'National Telecommunications of Florida'],
		55=>['DET&T',		'Denver and Ephrata Telephone and Telegraph Company'],
		56=>['VarTec',		'VarTec National, Incorporated'],
		57=>['ETS',		'Eastern Telephone Systems, Inc.'],
	},
	2=>{
	},
	3=>{
	},
	4=>{
	},
);
my %pc_blocks = (
	1=>{
		  0=>['Cleartel',	'Cleartel Communications'],
		  4=>['Business',	'Business Telecom'],
		  8=>['PA',		'Phone America'],
		 12=>['National',	'National Telephone'],
		 16=>['Vyvx',		'Vyvx Telecom'],
		 20=>['NTA',		'National Telecommunications of Austin'],
		 24=>['FPNE',		'First Phone of New England'],
		 28=>['SIS',		'Southern Interexchange Services, Inc.'],
		 32=>['NTS',		'NTS Communications'],
		 36=>['Digital',	'Digital Network'],
		 40=>['ATX',		'ATX Telecommunications Services'],
		 44=>['Vyvx',		'Vyvx Telecom'],
		 48=>['NNC',		'National Network Corp'],
		 52=>['StarTel',	'StarTel'],
		 56=>['TMC',		'TMC of San Diego'],
		 60=>['First',		'First Phone'],
		 64=>['CNI',		'CNI'],
		 68=>['WorldCom',	'WorldCom'],
		 72=>['WT&EC',		'Wilkes Telephone & Electric Company'],
		 76=>['Sandhill',	'Sandhill Telephone Cooperative'],
		 80=>['Chester',	'Chester Telephone'],
		 84=>['SJT&T',		'St. Joseph Telephone & Telegraph Company'],
		 88=>['ITC',		'Interstate Telephone Company'],
		 92=>['VUT',		'Vista-United Telecommunications'],
		 96=>['Brandenburg',	'Brandenburg Telephone Company'],
		100=>['FirstPhone',	'FirstPhone'],
		104=>['Chesnee',	'Chesnee Telephone Company'],
		108=>['Hargray',	'Hargray Telephone Company'],
		112=>['LaFourche',	'LaFourche Telephone Company'],
		116=>['Evans',		'Evans Telephone Company'],
		120=>['ICTC',		'Illinois Consolidated Telephone Company'],
		124=>['ICTC',		'Illinois Consolidated Telephone Company'],
		128=>['Roanoke',	'Roanoke Telephone Company'],
		132=>['INS',		'Iowa Network Services'],
		136=>['Telefonica',	'Telefonica Larga Distancia'],
		140=>['CHerokee',	'Cherokee Telephone Company'],
		144=>['Sears',		'Sears Technology Services, Inc.'],
		148=>['Phone One',	'Phone One'],
		152=>['Orwell',		'Orwell Telephone Company'],
		156=>['Call-Net',	'Call-Net Telecommunications Ltd.'],
	},
);

my $pc_assigments = {
	large_networks=>\%large_networks,
	small_networks=>\%small_networks,
	pc_blocks=>\%pc_blocks,
};

sub pcowner {
	my ($pc,$i) = @_;
	my ($ntw,$cls,$mem,$own);
	$ntw = $pc >> 16;
	$cls = ($pc >> 8) & 0xff;
	$mem = $pc & 0xff;
	if (5 < $ntw && $ntw < 255) {
		if ($cls != 0) {
			if ($own = $pc_assigments->{large_networks}->{$ntw}) {
				return $own->[$i];
			}
			if ($i) {
				return 'Unknown large network';
			}
			return '';
		}
	}
	if (1 <= $ntw && $ntw <= 4) {
		if ($cls != 0) {
			my $small;
			if ($small = $pc_assigments->{small_networks}->{$ntw}) {
				if ($own = $small->{$cls}) {
					return $own->[$i];
				}
			}
			if ($i) {
				return 'Unknown small network.';
			}
			return '';
		}
	}
	if ($ntw == 5) {
		if ($cls != 0) {
			my $cluster;
			if ($cluster = $pc_assigments->{pc_blocks}->{$cls}) {
				my $member = $mem & ~0x03;
				if ($own = $cluster->{$member}) {
					return $own->[$i];
				}
			}
			if ($i) {
				return 'Unknown point code block.';
			}
			return '';
		}
	}
	if ($i) {
		return 'Invalid point code.';
	}
	return '';
}

sub pcstring {
	my ($pc) = @_;
	my ($ntw,$cls,$mem,$own);
	if ($pc & ~0x3fff) {
		$ntw = $pc >> 16;
		$cls = ($pc >> 8) & 0xff;
		$mem = $pc & 0xff;
	} else {
		$ntw = $pc >> 11;
		$cls = ($pc >> 3) & 0xff;
		$mem = $pc & 0x7;
	}
	return "$ntw-$cls-$mem";
}

# distributions of message priorities should be:
# priority 3 0%-5%, 2 0%-20%, 1 30%-45%, 0 30%-45%
#
my %mtypes = (
	0=>{
		0x00 => ['snmm', 0x0],
		0x11 => ['coo',  0x8],
		0x12 => ['coa',  0x8],
		0x15 => ['cbd',  0x8],
		0x16 => ['cba',  0x8],
		0x21 => ['eco',  0x8],
		0x22 => ['eca',  0x8],
		0x31 => ['rct',  0x8],
		0x32 => ['tfc',  0x8],
		0x41 => ['tfp',  0x8],
		0x42 => ['tcp',  0x8],
		0x43 => ['tfr',  0x8],
		0x44 => ['tcr',  0x8],
		0x45 => ['tfa',  0x8],
		0x46 => ['tca',  0x8],
		0x51 => ['rst',  0xf],
		0x52 => ['rsr',  0x8],
		0x53 => ['rcp',  0x8],
		0x54 => ['rcr',  0x8],
		0x61 => ['lin',  0x8],
		0x62 => ['lun',  0x8],
		0x63 => ['lia',  0x8],
		0x64 => ['lua',  0x8],
		0x65 => ['lid',  0x8],
		0x66 => ['lfu',  0x8],
		0x67 => ['llt',  0x8],
		0x68 => ['lrt',  0x8],
		0x71 => ['tra',  0x8],
		0x72 => ['trw',  0x8],
		0x81 => ['dlc',  0x8],
		0x82 => ['css',  0x8],
		0x83 => ['cns',  0x8],
		0x84 => ['cnp',  0x8],
		0xa1 => ['upu',  0x8],
		0xa2 => ['upa',  0x8],
		0xa3 => ['upt',  0x8],
	},
	1=>{
		0x00 => ['sntm', 0x0],
		0x11 => ['sltm', 0x8],
		0x12 => ['slta', 0x8],
	},
	2=>{
		0x00 => ['snsm', 0x0],
		0x11 => ['sltm', 0x8],
		0x12 => ['slta', 0x8],
	},
	3=>{
		0x00 => ['sccp',  0x0],
		0x01 => ['cr',    0x3],
		0x02 => ['cc',    0x2],
		0x03 => ['cref',  0x2],
		0x04 => ['rlsd',  0x4],
		0x05 => ['rlc',   0x4],
		0x06 => ['dt1',   0x3],
		0x07 => ['dt2',   0x3],
		0x08 => ['ak',    0x3],
		0x09 => ['udt',   0x7],
		0x0a => ['udts',  0x7],
		0x0b => ['ed',    0x2],
		0x0c => ['ea',    0x2],
		0x0d => ['rsr',   0x2],
		0x0e => ['rsc',   0x2],
		0x0f => ['err',   0x2],
		0x10 => ['it',    0x2],
		0x11 => ['xudt',  0x7],
		0x12 => ['xudts', 0x7],
		0x13 => ['ludt',  0x7],
		0x14 => ['ludts', 0x7],
	},
	5=>{
		0x00 => ['isup', 0x0],
		0x01 => ['iam',  0x3],
		0x02 => ['sam',  0x0],
		0x03 => ['inr',  0x2],
		0x04 => ['inf',  0x2],
		0x05 => ['cot',  0x2],
		0x06 => ['acm',  0x2],
		0x07 => ['con',  0x0],
		0x08 => ['fot',  0x2],
		0x09 => ['anm',  0x4],
		0x0c => ['rel',  0x2],
		0x0d => ['sus',  0x2],
		0x0e => ['res',  0x2],
		0x10 => ['rlc',  0x4],
		0x11 => ['ccr',  0x2],
		0x12 => ['rsc',  0x1],
		0x13 => ['blo',  0x1],
		0x14 => ['ubl',  0x1],
		0x15 => ['bla',  0x1],
		0x16 => ['uba',  0x1],
		0x17 => ['grs',  0x1],
		0x18 => ['cgb',  0x1],
		0x19 => ['cgu',  0x1],
		0x1a => ['cgba', 0x1],
		0x1b => ['cgua', 0x1],
		0x1c => ['cmr',  0x0],
		0x1d => ['cmc',  0x0],
		0x1e => ['cmrj', 0x0],
		0x1f => ['far',  0x0],
		0x20 => ['faa',  0x0],
		0x21 => ['frj',  0x0],
		0x22 => ['fad',  0x0],
		0x23 => ['fai',  0x0],
		0x24 => ['lpa',  0x1],
		0x25 => ['csvq', 0x0],
		0x26 => ['csvr', 0x0],
		0x27 => ['drs',  0x0],
		0x28 => ['pam',  0x7],
		0x29 => ['gra',  0x1],
		0x2a => ['cqm',  0x1],
		0x2b => ['cqr',  0x1],
		0x2c => ['cpg',  0x2],
		0x2d => ['usr',  0x0],
		0x2e => ['ucic', 0x2],
		0x2f => ['cfn',  0x1],
		0x30 => ['olm',  0x0],
		0x31 => ['crg',  0x0],
		0x32 => ['nrm',  0x0],
		0x33 => ['fac',  0x7],
		0x34 => ['upt',  0x0],
		0x35 => ['upa',  0x0],
		0x36 => ['idr',  0x0],
		0x37 => ['irs',  0x0],
		0x38 => ['sgm',  0x1],
		0xe9 => ['cra',  0x1],
		0xea => ['crm',  0x1],
		0xeb => ['cvr',  0x1],
		0xec => ['cvt',  0x1],
		0xed => ['exm',  0x7],
		0xf8 => ['non',  0x0],
		0xfc => ['llm',  0x0],
		0xfd => ['cak',  0x0],
		0xfe => ['tcm',  0x0],
		0xff => ['mcp',  0x0],
	},
);

# -------------------------------------
package Logging;
use strict;
# -------------------------------------

#package Logging;
sub init {
	my $self = shift;
	$self->{logs} = [];
}

#package Logging;
sub new {
	my ($type,@args) = @_;
	my $self = {};
	bless $self,$type;
	$self->init(@args);
	return $self;
}

#package Logging;
sub showlog {
	my ($self,$canvas,$X,$Y) = @_;

	my $tw;
	if ($tw = $self->{logw}) {
		if ($tw->state eq 'iconic') {
			$tw->deiconify;
		} else {
			$tw->UnmapWindow;
		}
		$tw->MapWindow;
		return;
	}
	my $title = $self->identify." Logs";
	$tw = $canvas->toplevel->Toplevel(
		-title=>$title,
	);
	$tw->group($canvas->toplevel);
	#$tw->transient($canvas->toplevel);
	$tw->iconimage('icon');
	$tw->iconname($title);
	#$tw->resizable(0,0);
	$tw->positionfrom('user');
	$tw->geometry("+$X+$Y");
	$tw->protocol('WM_DELETE_WINDOW', [sub {
		my ($self) = @_;
		my $tw = $self->{logw};
		delete $self->{logw};
		$tw->destroy;
	},$self]);
	$self->{logw} = $tw;
	my $sc = $tw->Scrolled('ROText',
		-scrollbars=>'osoe',
	)->pack(
		-expand=>1,
		-fill=>'both',
		-side=>'left',
		-anchor=>'w',
	);
	my $ro = $sc->Subwidget('scrolled');
	$ro->delete('0.0', 'end');
	$ro->insert('end', join("\n",@{$self->{logs}}));
	$tw->update;
	$tw->MapWindow;
}

#package Logging;
sub log {
	my ($self,$text) = @_;
	push @{$self->{logs}}, $text;
}

# -------------------------------------
package Counts;
use strict;
# -------------------------------------

#package Counts;
sub init {
	my ($self,$interval) = @_;
	$self->{interval} = $interval;
	$self->{incs} = {};
	$self->{pegs} = {};
	$self->{durs} = {};
	$self->{iats} = {};
}

#package Counts;
sub new {
	my ($type,@args) = @_;
	my $self = {};
	bless $self,$type;
	$self->init(@args);
	return $self;
}

#package Counts;
sub inc {
	my ($self,$msg,$dir) = @_;
	my $li = $msg->{li};
	$self->{incs}->{$dir}->{sus} += 1;
	if ($li == 0) {
		$self->{incs}->{$dir}->{fisus} += 1;
		return;
	}
	if ($li == 1) {
		$self->{incs}->{$dir}->{lssus} += 1;
		return;
	}
	if ($li == 2) {
		$self->{incs}->{$dir}->{lss2s} += 1;
		return;
	}
	my $si = $msg->{si};
	my $mt = $msg->{mt};
	my $mp = $msg->{mp};
	$self->{incs}->{$dir}->{msus} += 1;
	$self->{incs}->{$dir}->{sis}->{$si}->{msus} += 1;
	$self->{incs}->{$dir}->{sis}->{$si}->{$mt}->{msus} += 1;
	$self->{incs}->{$dir}->{sis}->{$si}->{$mt}->{$mp} += 1;
	$self->{incs}->{$dir}->{mp}->{$mp} += 1;
}

#package Counts;
sub peg {
	my ($self,$event) = @_;
	$self->{pegs}->{$event} += 1;
}

#package Counts;
sub dur {
	my ($self,$event,$start,$end) = @_;
	my $dsecs = $end->{tv_sec} - $start->{tv_sec};
	my $dusec = $end->{tv_usec} - $start->{tv_usec};
	while ($dusec < 0 ) { $dsecs++; $dusec += 1000000; }
	my $dur = $dsecs + $dusec/1000000;
	$self->{durs}->{$event} += $dur;
	my $int = $dsecs;
	$int++ if $dusec > 0;
	$self->{durs}->{dist}->{$event}->{$int} += 1;
}

#package Counts;
sub iat {
	my ($self,$event,$ts) = @_;

	$self->{iats}->{$event} = [] unless exists $self->{iats}->{$event};
	push @{$self->{iats}->{$event}}, $ts;
}

# -------------------------------------
package style;
use strict;
# -------------------------------------

my %tframestyle = (
	-relief=>'groove',
	-borderwidth=>2,
);
my %tframepack = (
	-expand=>1,
	-fill=>'both',
	-side=>'top',
	-anchor=>'n',
	-padx=>3,
	-pady=>1,
);
my %labelright = (
	-anchor=>'e',
	-justify=>'right',
	-relief=>'groove',
	-borderwidth=>2,
);
my %labelcenter = (
	-anchor=>'s',
	-justify=>'center',
	-relief=>'groove',
	-borderwidth=>2,
);
my %labelgrid = (
);
my %entryinput = (
	-background=>'white',
	-exportselection=>1,
);
my %entryleft = (
	%entryinput,
	-state=>'readonly',
	-relief=>'groove',
	-borderwidth=>2,
);
my %entryright = (
	%entryleft,
	-justify=>'right',
	-width=>8,
);
my %entrycenter = (
	%entryleft,
	-justify=>'center',
);
my %entrygrid = (
);
my %buttonleft = (
	-anchor=>'w',
	-justify=>'left',
	-indicatoron=>1,
	-state=>'disabled',
);
my %optionleft = (
	-anchor=>'w',
	-justify=>'left',
	-indicatoron=>0,
);

# -------------------------------------
package Stats;
use strict;
use vars qw(@ISA);
@ISA = qw(Counts);
# -------------------------------------

#package Stats;
sub init {
	my $self = shift;
	Counts::init($self);
	$self->{hist} = {};
}

#package Stats;
sub new {
	my ($type,@args) = @_;
	my $self = {};
	bless $self,$type;
	$self->init(@args);
	return $self;
}

#package Stats;
sub interval {
	my ($self,$ts) = @_;
	my $int = $ts->{tv_sec};
	$int++ if ($ts->{tv_usec} > 0);
	$int = int(($int + 299)/300);
	return $int;
}

#package Stats;
sub hist {
	my ($self,$int) = @_;
	my $obj;
	unless ($obj = $self->{hist}->{$int}) {
		$obj = $self->{hist}->{$int} = Counts->new($int);
	}
	return $obj;
}

#package Stats;
sub inc {
	my ($self,$msg,$dir) = @_;
#	my $int = $self->interval($msg->{hdr});
#	my $hist = $self->hist($int);
#	$hist->inc($msg,$dir);
	$self->Counts::inc($msg,$dir);
}

#package Stats;
sub peg {
	my ($self,$event,$ts) = @_;
#	my $int = $self->interval($ts);
#	my $hist = $self->hist($int);
#	$hist->peg($event);
	$self->Counts::peg($event);
}

#package Stats;
sub dur {
	my ($self,$event,$start,$end) = @_;
#	my $s = $self->interval($start);
#	my $e = $self->interval($end);
#	for (my $t = $s; $t <= $e; $t += 300) {
#		my $hist = $self->hist($t);
#		if ($t == $s) {
#			$hist->dur($event,$start,{tv_sec=>$t+300,tv_usec=>0});
#		} elsif ($t == $e) {
#			$hist->dur($event,{tv_sec=>$t,tv_usec=>0},$end);
#		} else {
#			$hist->dur($event,{tv_sec=>$t,tv_usec=>0},{tv_sec=>$t+300,tv_usec=>0});
#		}
#	}
	$self->Counts::dur($event,$start,$end);
}

#package Stats;
sub iat {
	my ($self,$event,$ts) = @_;
	$self->Counts::iat($event,$ts);
}

# -------------------------------------
package MsgStats;
use strict;
use vars qw(@ISA);
@ISA = qw(Stats);
# -------------------------------------

use constant {
	CTS_UNINIT	=> 0,
	CTS_IDLE	=> 1,
	CTS_WAIT_ACM	=> 2,
	CTS_WAIT_ANM	=> 3,
	CTS_ANSWERED	=> 4,
	CTS_SUSPENDED	=> 5,
	CTS_WAIT_RLC	=> 6,
	CTS_SEND_RLC	=> 7,
	CTS_COMPLETE	=> 8,
};

#package MsgStats;
sub init {
	my ($self,@args) = @_;
	my $self = shift;
	Stats::init($self,@args);
	$self->{dist} = {};
}

#package MsgStats;
sub new {
	my ($type,@args) = @_;
	my $self = {};
	bless $self,$type;
	$self->init(@args);
	return $self;
}

#package MsgStats;
sub stats {
	my ($self,$canvas,$X,$Y) = @_;
	my $row = 0;
	my ($tw,$w,$bmsg);
	if ($tw = $self->{stats}) {
		if ($tw->state eq 'iconic') {
			$tw->deiconify;
		} else {
			$tw->UnmapWindow;
		}
	} else {
		my $title = $self->identify." Message Statistics";
		$tw = $canvas->toplevel->Toplevel(
			-title=>$title,
		);
		$tw->group($canvas->toplevel);
		#$tw->transient($canvas->toplevel);
		$tw->iconimage('icon');
		$tw->iconname($title);
		#$tw->resizable(0,0);
		$tw->positionfrom('user');
		$tw->sizefrom('program');
		#$tw->minsize(600,400);
		$tw->geometry("+$X+$Y");
		$tw->protocol('WM_DELETE_WINDOW', [sub {
			my $self = shift;
			my $tw = $self->{stats};
			delete $self->{stats};
			$tw->destroy;
		},$self]);
		$self->{stats} = $tw;
		my $balloon = $tw->Balloon(-statusbar=>$::statusbar);
		my $p = $tw->Scrolled('Pane',
			-scrollbars=>'osoe',
			-sticky=>'ewns',
		)->pack(%tframepack);
		my $f = $p->Subwidget('scrolled');
		my $s = $f->Frame->pack(%tframepack);
		if ($self->{incs}->{0}->{fisus} or $self->{incs}->{1}->{fisus}) {
			$w = $s->Label(%labelright,
				-text=>'FISUs:',
			)->grid(-row=>$row,-column=>0,-sticky=>'ewns');
			$balloon->attach($w,
				-balloonmsg=>"Number of FISUs sent and received.",
			);
			$w = $s->Entry(%entryright,
				-textvariable=>\$self->{incs}->{0}->{fisus},
			)->grid(-row=>$row,-column=>1,-sticky=>'ewns');
			$balloon->attach($w,
				-balloonmsg=>"Number of FISUs sent.",
			);
			$w = $s->Entry(%entryright,
				-textvariable=>\$self->{incs}->{1}->{fisus},
			)->grid(-row=>$row++,-column=>2,-sticky=>'ewns');
			$balloon->attach($w,
				-balloonmsg=>"Number of FISUs received.",
			);
		}
		if ($self->{incs}->{0}->{lssus} or $self->{incs}->{1}->{lssus}) {
			$w = $s->Label(%labelright,
				-text=>'1-octet LSSUs:',
			)->grid(-row=>$row,-column=>0,-sticky=>'ewns');
			$balloon->attach($w,
				-balloonmsg=>"Number of 1-octet LSSUs sent and received.",
			);
			$s->Entry(%entryright,
				-textvariable=>\$self->{incs}->{0}->{lssus},
			)->grid(-row=>$row,-column=>1,-sticky=>'ewns');
			$w = $balloon->attach($w,
				-balloonmsg=>"Number of 1-octet LSSUs sent.",
			);
			$s->Entry(%entryright,
				-textvariable=>\$self->{incs}->{1}->{lssus},
			)->grid(-row=>$row++,-column=>2,-sticky=>'ewns');
			$w = $balloon->attach($w,
				-balloonmsg=>"Number of 1-octet LSSUs received.",
			);
		}
		if ($self->{incs}->{0}->{lss2s} or $self->{incs}->{1}->{lss2s}) {
			$w = $s->Label(%labelright,
				-text=>'2-octet LSSUs:',
			)->grid(-row=>$row,-column=>0,-sticky=>'ewns');
			$balloon->attach($w,
				-balloonmsg=>"Number of 2-octet LSSUs sent and received.",
			);
			$w = $s->Entry(%entryright,
				-textvariable=>\$self->{incs}->{0}->{lss2s},
			)->grid(-row=>$row,-column=>1,-sticky=>'ewns');
			$balloon->attach($w,
				-balloonmsg=>"Number of 2-octet LSSUs sent.",
			);
			$w = $s->Entry(%entryright,
				-textvariable=>\$self->{incs}->{1}->{lss2s},
			)->grid(-row=>$row++,-column=>2,-sticky=>'ewns');
			$balloon->attach($w,
				-balloonmsg=>"Number of 2-octet LSSUs received.",
			);
		}
		if ($self->{incs}->{0}->{msus} or $self->{incs}->{1}->{msus}) {
			$w = $s->Label(%labelright,
				-text=>'MSUs:',
			)->grid(-row=>$row,-column=>0,-sticky=>'ewns');
			$balloon->attach($w,
				-balloonmsg=>"Number of MSUs sent and received.",
			);
			$w = $s->Entry(%entryright,
				-textvariable=>\$self->{incs}->{0}->{msus},
			)->grid(-row=>$row,-column=>1,-sticky=>'ewns');
			$balloon->attach($w,
				-balloonmsg=>"Number of MSUs sent.",
			);
			$w = $s->Entry(%entryright,
				-textvariable=>\$self->{incs}->{1}->{msus},
			)->grid(-row=>$row,-column=>2,-sticky=>'ewns');
			$balloon->attach($w,
				-balloonmsg=>"Number of MSUs received.",
			);
			for (my $mp = 0; $mp < 4; $mp++) {
				my $p;
				my $mpp0 = sprintf('%6.2f', ($self->{incs}->{0}->{mp}->{$mp}*100)/(($p=$self->{incs}->{0}->{msus})?$p:1));
				my $mpp1 = sprintf('%6.2f', ($self->{incs}->{1}->{mp}->{$mp}*100)/(($p=$self->{incs}->{1}->{msus})?$p:1));
				if ($mp == 3) {
					$bmsg = "\nThis value should be between 0% and 5%.";
				} elsif ($mp == 2) {
					$bmsg = "\nThis value should be between 0% and 20%.";
				} else {
					$bmsg = "\nThis value should be between 30% and 45%.";
				}
				$w = $s->Label(%labelright,
					-text=>"mp($mp)",
				)->grid(-row=>$row,-column=>3,-sticky=>'ewns');
				$balloon->attach($w,
					-balloonmsg=>"Number of MP($mp) MSUs sent and received.",
				);
				$w = $s->Entry(%entryright,
					-textvariable=>\$self->{incs}->{0}->{mp}->{$mp},
					-validatecommand=>[sub{
						my ($mpp,$mp,$self,$row,$col,$old,$proposed,$index,@args) = @_;
						my $p;
						$$mpp = sprintf('%6.2f', ($self->{incs}->{0}->{mp}->{$mp}*100)/(($p=$self->{incs}->{0}->{msus})?$p:1));
						return 1;
					},\$mpp0,$mp,$self],
					-validate=>'all',
				)->grid(-row=>$row,-column=>4,-sticky=>'ewns');
				$balloon->attach($w,
					-balloonmsg=>"Number of MP($mp) MSUs sent.",
				);
				$w = $s->Entry(%entryright,
					-textvariable=>\$self->{incs}->{1}->{mp}->{$mp},
					-validatecommand=>[sub{
						my ($mpp,$mp,$self,$row,$col,$old,$proposed,$index,@args) = @_;
						my $p;
						$$mpp = sprintf('%6.2f', ($self->{incs}->{1}->{mp}->{$mp}*100)/(($p=$self->{incs}->{1}->{msus})?$p:1));
						return 1;
					},\$mpp1,$mp,$self],
					-validate=>'all',
				)->grid(-row=>$row,-column=>5,-sticky=>'ewns');
				$balloon->attach($w,
					-balloonmsg=>"Number of MP($mp) MSUs received.",
				);
				$w = $s->Label(%labelright,
					-text=>"mp($mp)%",
				)->grid(-row=>$row,-column=>6,-sticky=>'ewns');
				$balloon->attach($w,
					-balloonmsg=>"Percentage of MP($mp) MSUs sent and received.$bmsg",
				);
				$w = $s->Entry(%entryright,
					-textvariable=>\$mpp0,
				)->grid(-row=>$row,-column=>7,-sticky=>'ewns');
				$balloon->attach($w,
					-balloonmsg=>"Percentage of MP($mp) MSUs sent.$bmsg",
				);
				$w = $s->Entry(%entryright,
					-textvariable=>\$mpp1,
				)->grid(-row=>$row++,-column=>8,-sticky=>'ewns');
				$balloon->attach($w,
					-balloonmsg=>"Percentage of MP($mp) MSUs received.$bmsg",
				);
			}
		}
		if ($self->{incs}->{0}->{sis} or $self->{incs}->{1}->{sis}) {
			my %keys = ();
			foreach my $k (keys %{$self->{incs}->{0}->{sis}},
				       keys %{$self->{incs}->{1}->{sis}}) {
				$keys{$k} = 1;
			}
			foreach my $si (sort {$a <=> $b} keys %keys) {
				next unless (exists $mtypes{$si});
				$w = $s->Label(%labelright,
					-text=>"$mtypes{$si}->{0x00}->[0]($si):",
				)->grid(-row=>$row,-column=>0,-sticky=>'ewns');
				$balloon->attach($w,
					-balloonmsg=>"Number of \U$mtypes{$si}->{0x00}->[0]($si)\E messages sent and received.",
				);
				$w = $s->Entry(%entryright,
					-textvariable=>\$self->{incs}->{0}->{sis}->{$si}->{msus},
				)->grid(-row=>$row,-column=>1,-sticky=>'ewns');
				$balloon->attach($w,
					-balloonmsg=>"Number of \U$mtypes{$si}->{0x00}->[0]($si)\E messages sent.",
				);
				$w = $s->Entry(%entryright,
					-textvariable=>\$self->{incs}->{1}->{sis}->{$si}->{msus},
				)->grid(-row=>$row,-column=>2,-sticky=>'ewns');
				$balloon->attach($w,
					-balloonmsg=>"Number of \U$mtypes{$si}->{0x00}->[0]($si)\E messages received.",
				);
				my $mtcount = 0;
				my %keys2 = ();
				foreach my $k (keys %{$self->{incs}->{0}->{sis}->{$si}},
					       keys %{$self->{incs}->{1}->{sis}->{$si}}) {
					$keys2{$k} = 1;
				}
				foreach my $mt (sort {$a <=> $b} keys %keys2) {
					next if $mt eq 'msus';
					next unless exists $mtypes{$si}->{$mt};
					$mtcount += 1;
					$w = $s->Label(%labelright,
						-text=>"$mtypes{$si}->{$mt}->[0]($mt):",
					)->grid(-row=>$row,-column=>3,-sticky=>'ewns');
					$balloon->attach($w,
						-balloonmsg=>"Number of \U$mtypes{$si}->{$mt}->[0]($mt)\E messages sent and received.",
					);
					$w = $s->Entry(%entryright,
						-textvariable=>\$self->{incs}->{0}->{sis}->{$si}->{$mt}->{msus},
					)->grid(-row=>$row,-column=>4,-sticky=>'ewns');
					$balloon->attach($w,
						-balloonmsg=>"Number of \U$mtypes{$si}->{$mt}->[0]($mt)\E messages sent.",
					);
					$w = $s->Entry(%entryright,
						-textvariable=>\$self->{incs}->{1}->{sis}->{$si}->{$mt}->{msus},
					)->grid(-row=>$row,-column=>5,-sticky=>'ewns');
					$balloon->attach($w,
						-balloonmsg=>"Number of \U$mtypes{$si}->{$mt}->[0]($mt)\E messages received.",
					);
					my $mpcount = 0;
					my %keys3 = ();
					foreach my $k (keys %{$self->{incs}->{0}->{sis}->{$si}->{$mt}},
						       keys %{$self->{incs}->{1}->{sis}->{$si}->{$mt}}) {
						$keys3{$k} = 1;
					}
					foreach my $mp (sort {$a <=> $b} keys %keys3) {
						next if $mp eq 'msus';
						$mpcount += 1;
						my $color = 'black';
						$bmsg = '';
						unless ($mtypes{$si}->{$mt}->[1] & (1<<$mp)) {
							$color = 'red';
							$bmsg = "\nMP($mp) is not valid for \U$mtypes{$si}->{$mt}->[0]($mt)\E messages.";
						}
						$w = $s->Label(%labelright,
							-fg=>$color,
							-text=>"mp($mp):",
						)->grid(-row=>$row,-column=>6,-sticky=>'ewns');
						$balloon->attach($w,
							-balloonmsg=>"Number of MP($mp) \U$mtypes{$si}->{$mt}->[0]($mt)\E messages sent and received.$bmsg",
						);
						$w = $s->Entry(%entryright,
							-fg=>$color,
							-textvariable=>\$self->{incs}->{0}->{sis}->{$si}->{$mt}->{$mp},
						)->grid(-row=>$row,-column=>7,-sticky=>'ewns');
						$balloon->attach($w,
							-balloonmsg=>"Number of MP($mp) \U$mtypes{$si}->{$mt}->[0]($mt)\E messages sent.$bmsg",
						);
						$w = $s->Entry(%entryright,
							-fg=>$color,
							-textvariable=>\$self->{incs}->{1}->{sis}->{$si}->{$mt}->{$mp},
						)->grid(-row=>$row++,-column=>8,-sticky=>'ewns');
						$balloon->attach($w,
							-balloonmsg=>"Number of MP($mp) \U$mtypes{$si}->{$mt}->[0]($mt)\E messages received.$bmsg",
						);
					}
					$row++ unless $mpcount;
				}
				$row++ unless $mtcount;
			}
		}
		$s->update;
		my $x = $s->width+40;
		my $y = $s->height+40;
		$tw->geometry("=$x"."x$y");
	}
	$tw->update;
	$tw->MapWindow;
}

my %centerblack = ( -anchor=>'center', -fill=>'black', -justify=>'center' );
my %rightblack = ( -anchor=>'e', -fill=>'black', -justify=>'right' );
my %blackline = ( -arrow=>'none', -capstyle=>'round', -fill=>'black', -joinstyle=>'round', -smooth=>0, -width=>1 );
my %greyline = ( -arrow=>'none', -capstyle=>'round', -fill=>'grey', -joinstyle=>'round', -smooth=>0, -width=>1 );
my %dashline = ( -arrow=>'none', -capstyle=>'round', -fill=>'grey', -joinstyle=>'round', -smooth=>0, -width=>1, -dash=>[3,2] );
my %blackcurve = ( -arrow=>'none', -capstyle=>'round', -fill=>'black', -joinstyle=>'round', -smooth=>1, -width=>1 );
my %blueline = ( -arrow=>'none', -capstyle=>'round', -fill=>'blue', -joinstyle=>'round', -smooth=>0, -width=>2 );

#package MsgStats;
sub dist {
	my ($self,$event,$kind,$c) = @_;
	# copy the data
	my $h = {}; while (my ($k,$v) = each %{$self->{durs}->{dist}->{$event}}) { $h->{$k} = $v; }
	my ($maxx,$minx,$maxy,$miny);
	foreach my $v (sort {$b<=>$a} values %{$h}) { $maxy = $v unless defined $maxy; $miny = $v; }
	# remove anomalies
	if ($miny * 1000 < $maxy) {
		while (my ($k,$v) = each %{$h}) { delete $h->{$k} if $v * 1000 < $maxy; }
		foreach my $v (sort {$a<=>$b} values %{$h}) { $miny = $v; last; }
	}
	if ($maxy == $miny) { $maxy++; }
	foreach my $k (sort {$b<=>$a} keys %{$h}) { $maxx = $k unless defined $maxx; $minx = $k; }
	if ($maxx == $minx) { $maxx++; }
	for (my $i = $minx; $i <= $maxx; $i++) { unless (exists $h->{$i}) { $h->{$i} = 0; $miny = 0; } }
	my $t = 0; for (my $i = $minx; $i <= $maxx; $i++) { $t += $h->{$i}; if ($kind == 1) { $h->{$i} = $t; } }
	for (my $i = $minx; $i <= $maxx; $i++) { $h->{$i} /= $t; }
	if ($kind == 1) { $maxy = 1; } else { $maxy /= $t; } $miny = 0;
	my ($scalex,$scaley) = (500/($maxx-$minx),300/($maxy-$miny));
	my @coords = ();
	foreach my $k (sort {$a<=>$b} keys %{$h}) {
		my $v = $h->{$k};
		my $x = 50 + ($k - $minx) * $scalex;
		my $y = 350 - ($v - $miny) * $scaley;
		push @coords, $x;
		push @coords, $y;
	}
	$c->createText(300,385, %centerblack, -text=>'seconds of duration');
	$c->createText(550,385, %rightblack, -text=>"total calls = $t");
	#$c->createText(45,200, %rightblack, -text=>'calls');
	$c->createLine(50,50,50,350, %blackline);
	$c->createLine(50,350,550,350, %blackline);
	my $tickx = 10**(int(log($maxx-$minx)/log(10)));
	$c->createText(50,368, %centerblack, -text=>$minx);
	$c->createLine(50,50,50,360, %blackline);
	for (my $x = 0; $x < $maxx; $x += $tickx) {
		my $X = 50 + ($x - $minx) * $scalex;
		next if $X < 50;
		$c->createLine($X,50,$X,360, %blackline);
		next if $X > 500 || $X < 100;
		$c->createText($X,368, %centerblack, -text=>$x);
	}
	for (my $x = $tickx/2; $x < $maxx; $x += $tickx) {
		next if $x < $minx;
		my $X = 50 + ($x - $minx) * $scalex;
		$c->createLine($X,50,$X,357, %greyline);
	}
	foreach my $s ( 1, 2, 3, 4, 6, 7, 8, 9 ) {
		for (my $x = $s*$tickx/10; $x < $maxx; $x += $tickx) {
			next if $x < $minx;
			my $X = 50 + ($x - $minx) * $scalex;
			$c->createLine($X,50,$X,353, %dashline);
		}
	}
	my $format = ($kind == 1)?'%.1f':'%.3f';
	$c->createText(550,368, %centerblack, -text=>$maxx);
	$c->createLine(550,50,550,360, %blackline);
	$c->createText(35,350, %rightblack, -text=>sprintf($format,$miny));
	$c->createLine(550,350,40,350, %blackline);
	my $ticky = 10**(int(log($maxy-$miny)/log(10))-1);
	for (my $y = 0; $y < $maxy; $y += $ticky) {
		my $Y = 350 - ($y - $miny) * $scaley;
		next if $Y > 350;
		$c->createLine(550,$Y,40,$Y, %blackline);
		next if $Y < 60 || $Y > 340;
##		#next if $Y > 190 && $Y < 210;
		$c->createText(35, $Y, %rightblack, -text=>sprintf($format,$y));
	}
	for (my $y = $ticky/2; $y < $maxy; $y += $ticky) {
		next if $y < $miny;
		my $Y = 350 - ($y - $miny) * $scaley;
		$c->createLine(550,$Y,43,$Y, %greyline);
	}
	foreach my $s ( 1, 2, 3, 4, 6, 7, 8, 9 ) {
		for (my $y = $s*$ticky/10; $y < $maxy; $y += $ticky) {
			next if $y < $miny;
			my $Y = 350 - ($y - $miny) * $scaley;
			$c->createLine(550,$Y,47,$Y, %dashline);
		}
	}
	$c->createText(35,50, %rightblack, -text=>sprintf($format, $maxy));
	$c->createLine(550,50,40,50, %blackline);
	$c->createLine(@coords, %blueline);
	$c->createLine(@coords, %blackcurve);
	$c->update;
	$c->{_mydata} = {};
	$c->{_mydata}->{w} = 600;
	$c->{_mydata}->{h} = 400;
	$c->CanvasBind('<Configure>',[\&MsgStats::resizedist,Tk::Ev('w'),Tk::Ev('h')]);
}

#package MsgStats;
sub phase {
	my ($self,$event,$kind,$c) = @_;
	my @iats = ();
	my ($imax,$t);
	my $count = 0;
	unless ($self->{iats}->{$event}) {
		$c->createText(300,300,%centerblack,-text=>'NO DATA');
		return;
	}
	foreach my $ts (@{$self->{iats}->{$event}}) {
		my $n = $ts;
		if (defined $t) {
			my $i = { tv_sec=>$n->{tv_sec}-$t->{tv_sec}, tv_usec=>$n->{tv_usec}-$t->{tv_usec} };
			while ($i->{tv_usec} < 0) {
				$i->{tv_sec}--;
				$i->{tv_usec} += 1000000;
			}
			my $v = $i->{tv_sec} + $i->{tv_usec}/1000000;
			push @iats, $v;
			$imax = $v unless defined $imax;
			if ($v > $imax) { $imax = $v; }
			$count++;
		}
		$t = $n;
	}
	unless ($count) {
		$c->createText(300,300,%centerblack,-text=>'NO DATA');
		return;
	}
	my $scale = 500/$imax;
	$c->createText(300,585, %centerblack, -text=>'X[i] (seconds)');
	$c->createText(550,585, %rightblack, -text=>"total interarrivals = $count");
	$c->createText(45,300, %rightblack, -text=>'X[i+1]');
	$c->createLine(50,50,50,550, %blackline);
	$c->createLine(50,550,550,550, %blackline);
	my $tick = 10**(int(log($imax)/log(10)));
	$c->createText(50,568, %centerblack, -text=>0);
	$c->createLine(50,50,50,560, %blackline);
	for (my $x = 0; $x < $imax; $x += $tick) {
		my $X = 50 + $x * $scale;
		next if $X < 50;
		$c->createLine($X,50,$X,560, %blackline);
		next if $X > 500 || $X < 100;
		$c->createText($X,568, %centerblack, -text=>$x);
	}
	for (my $x = $tick/2; $x < $imax; $x += $tick) {
		my $X = 50 + $x * $scale;
		$c->createLine($X,50,$X,557, %greyline);
	}
	foreach my $s ( 1, 2, 3, 4, 6, 7, 8, 9 ) {
		for (my $x = $s*$tick/10; $x < $imax; $x += $tick) {
			my $X = 50 + $x * $scale;
			$c->createLine($X,50,$X,553, %dashline);
		}
	}
	$c->createText(550,568, %centerblack, -text=>sprintf('%.2f',$imax));
	$c->createLine(550,50,550,560, %blackline);
	$c->createText(35,550, %rightblack, -text=>0);
	$c->createLine(550,550,40,550, %blackline);
	for (my $y = 0; $y < $imax; $y += $tick) {
		my $Y = 550 - $y * $scale;
		next if $Y > 550;
		$c->createLine(550,$Y,40,$Y, %blackline);
		next if $Y < 60 || $Y > 540;
		next if $Y > 290 && $Y < 310;
		$c->createText(35, $Y, %rightblack, -text=>$y);
	}
	for (my $y = $tick/2; $y < $imax; $y += $tick) {
		my $Y = 550 - $y * $scale;
		$c->createLine(550,$Y,43,$Y, %greyline);
	}
	foreach my $s ( 1, 2, 3, 4, 6, 7, 8, 9 ) {
		for (my $y = $s*$tick/10; $y < $imax; $y += $tick) {
			my $Y = 550 - $y * $scale;
			$c->createLine(550,$Y,47,$Y, %dashline);
		}
	}
	$c->createText(35,50, %rightblack, -text=>sprintf('%.2f',$imax));
	$c->createLine(550,50,40,50, %blackline);
	my $ti = shift @iats;
	foreach my $tip1 (@iats) {
		my $X = 50 + $ti * $scale;
		my $Y = 550 - $tip1 * $scale;
		$c->createOval($X-1,$Y-1,$X+1,$Y+1,
			-fill=>'black',
			-outline=>'black',
			-width=>0,
		);
		$ti = $tip1;
	}
	$c->update;
	$c->{_mydata} = {};
	$c->{_mydata}->{w} = 600;
	$c->{_mydata}->{h} = 600;
	$c->CanvasBind('<Configure>',[\&MsgStats::resizedist,Tk::Ev('w'),Tk::Ev('h')]);
}

#package MsgStats;
sub pdf {
	my ($self,$event,$kind,$c) = @_;
	my @iats = ();
	my ($max,$maxx,$maxy,$t);
	my $count = 0;
	unless ($self->{iats}->{$event}) {
		$c->createText(300,300,%centerblack,-text=>'NO DATA');
		return;
	}
	foreach my $ts (@{$self->{iats}->{$event}}) {
		my $n = $ts;
		if (defined $t) {
			my $i = { tv_sec=>$n->{tv_sec}-$t->{tv_sec}, tv_usec=>$n->{tv_usec}-$t->{tv_usec} };
			while ($i->{tv_usec} < 0) {
				$i->{tv_sec}--;
				$i->{tv_usec} += 1000000;
			}
			my $v = $i->{tv_sec} + $i->{tv_usec}/1000000;
			push @iats, $v;
			$max = $v unless defined $max;
			if ($v > $max) { $max = $v; }
			$count++;
		}
		$t = $n;
	}
	unless ($count) {
		$c->createText(300,300,%centerblack,-text=>'NO DATA');
		return;
	}
	my $pow = int(log($max)/log(10))-2;
	my $int = 10**$pow;
	my $h = {};
	foreach my $v (@iats) {
		my $i = $v/$int;
		if (int($i) < $i) {
			$v = (int($i) + 1);
		} else {
			$v = int($i);
		}
		$h->{$v}++;
	}
	foreach my $v (sort {$b<=>$a} values %{$h}) { $maxy = $v; last; }
	foreach my $k (sort {$b<=>$a} keys %{$h}) { $maxx = $k; last; }
	for (my $i = 0; $i <= $maxx; $i++) { unless (exists $h->{$i}) { $h->{$i} = 0; } }
	my $t = 0; for (my $i = 0; $i <= $maxx; $i++) { $t += $h->{$i}; if ($kind == 4) { $h->{$i} = $t; } }
	for (my $i = 0; $i <= $maxx; $i++) { $h->{$i} /= $t; }
	if ($kind == 4) { $maxy = 1; } else { $maxy /= $t; }
	my ($scalex,$scaley) = (500/$maxx,300/$maxy);
	my @coords = ();
	foreach my $k (sort {$a<=>$b} keys %{$h}) {
		my $v = $h->{$k};
		my $x = 50 + $k * $scalex;
		my $y = 350 - $v * $scaley;
		push @coords, $x;
		push @coords, $y;
	}
	$c->createText(300,385, %centerblack, -text=>'seconds between arrivals');
	$c->createText(550,385, %rightblack, -text=>"total interarrivals = $t");
	#$c->createText(45,200, %rightblack, -text=>'calls');
	$c->createLine(50,50,50,350, %blackline);
	$c->createLine(50,350,550,350, %blackline);
	my $tickx = 10**(int(log($maxx)/log(10)));
	$c->createText(50,368, %centerblack, -text=>0);
	$c->createLine(50,50,50,360, %blackline);
	for (my $x = 0; $x < $maxx; $x += $tickx) {
		my $X = 50 + $x * $scalex;
		next if $X < 50;
		$c->createLine($X,50,$X,360, %blackline);
		next if $X > 500 || $X < 100;
		$c->createText($X,368, %centerblack, -text=>$x*$int);
	}
	for (my $x = $tickx/2; $x < $maxx; $x += $tickx) {
		my $X = 50 + $x * $scalex;
		$c->createLine($X,50,$X,357, %greyline);
	}
	foreach my $s ( 1, 2, 3, 4, 6, 7, 8, 9 ) {
		for (my $x = $s*$tickx/10; $x < $maxx; $x += $tickx) {
			my $X = 50 + $x * $scalex;
			$c->createLine($X,50,$X,353, %dashline);
		}
	}
	my $format = ($kind == 4)?'%.1f':'%.3f';
	$c->createText(550,368, %centerblack, -text=>$maxx*$int);
	$c->createLine(550,50,550,360, %blackline);
	$c->createText(35,350, %rightblack, -text=>0);
	$c->createLine(550,350,40,350, %blackline);
	my $ticky = 10**(int(log($maxy)/log(10))-1);
	for (my $y = 0; $y < $maxy; $y += $ticky) {
		my $Y = 350 - $y * $scaley;
		next if $Y > 350;
		$c->createLine(550,$Y,40,$Y, %blackline);
		next if $Y < 60 || $Y > 340;
##		#next if $Y > 190 && $Y < 210;
		$c->createText(35, $Y, %rightblack, -text=>sprintf($format,$y));
	}
	for (my $y = $ticky/2; $y < $maxy; $y += $ticky) {
		my $Y = 350 - $y * $scaley;
		$c->createLine(550,$Y,43,$Y, %greyline);
	}
	foreach my $s ( 1, 2, 3, 4, 6, 7, 8, 9 ) {
		for (my $y = $s*$ticky/10; $y < $maxy; $y += $ticky) {
			my $Y = 350 - $y * $scaley;
			$c->createLine(550,$Y,47,$Y, %dashline);
		}
	}
	$c->createText(35,50, %rightblack, -text=>sprintf($format, $maxy));
	$c->createLine(550,50,40,50, %blackline);
	$c->createLine(@coords, %blueline);
	$c->createLine(@coords, %blackcurve);
	$c->update;
	$c->{_mydata} = {};
	$c->{_mydata}->{w} = 600;
	$c->{_mydata}->{h} = 400;
	$c->CanvasBind('<Configure>',[\&MsgStats::resizedist,Tk::Ev('w'),Tk::Ev('h')]);
}

#package MsgStats;
sub plot {
	my ($self,$w,$event,$prefix,$label,$X,$Y,$kind) = @_;
	my $tw;
	if ($tw = $self->{dist}->{$event}->{$kind}) {
		if ($tw->state eq 'iconic') {
			$tw->deiconify;
		} else {
			$tw->UnmapWindow;
		}
		$tw->MapWindow;
		return;
	}
	my $title;
	if ($kind == 0) {
		$title = "probability density of $label holding times";
	} elsif ($kind == 1) {
		$title = "cummulative distribution of $label holding times";
	} elsif ($kind == 2) {
		$title = "phase plot of $label interarrival times";
	} elsif ($kind == 3) {
		$title = "probability density of $label interarrival times";
	} elsif ($kind == 4) {
		$title = "cummulative distribution of $label interarrival times";
	}
	$tw = $w->toplevel->Toplevel(
		-title=>$title,
	);
	$tw->group($w->toplevel);
	#$tw->transient($w->toplevel);
	$tw->iconimage('icon');
	$tw->iconname($title);
	#$tw->resizable(0,0);
	$tw->positionfrom('user');
	$tw->geometry("+$X+$Y");
	$tw->protocol('WM_DELETE_WINDOW', [sub {
		my ($self,$event,$kind) = @_;
		my $tw = $self->{dist}->{$event}->{$kind};
		delete $self->{dist}->{$event}->{$kind};
		$tw->destroy;
	},$self,$event,$kind]);
	$self->{dist}->{$event}->{$kind} = $tw;
	my ($width,$height) = (600,400);
	if ($kind == 2) { ($width,$height) = (600,600); }
	my $c = $tw->Canvas(
		-confine=>1,
		-width=>$width,
		-height=>$height,
		-xscrollincrement=>0,
		-yscrollincrement=>0,
		-background=>'white',
	)->pack(
		-expand=>1,
		-fill=>'both',
		-side=>'left',
		-anchor=>'w',
	);
	$c->createText(300,20, %centerblack, -text=>"\U$title");
	my $id = $self->identify;
	$c->createText(300,35, %centerblack, -text=>"$prefix for $id");
	if ($kind == 0 || $kind == 1) {
		$self->dist($event,$kind,$c);
	} elsif ($kind == 2) {
		$self->phase($event,$kind,$c);
	} elsif ($kind == 3 || $kind == 4) {
		$self->pdf($event,$kind,$c);
	}
	$tw->update;
	$tw->MapWindow;
}

#package MsgStats;
sub resizedist {
	my ($c,$w,$h) = @_;
	my $ow = $c->{_mydata}->{w};
	my $oh = $c->{_mydata}->{h};
	$c->scale('all',0,0,$w/$ow,$h/$oh);
	$c->{_mydata}->{w} = $w;
	$c->{_mydata}->{h} = $h;
}

#package MsgStats;
sub plotmenu {
	my ($self,$tw,$event,$prefix,$label,$X,$Y) = @_;
	my $m = $tw->Menu(
		-tearoff=>1,
		-title=>'Plot Menu',
	);
	$m->add('command',
		-label=>'Holding PDF...',
		-underline=>0,
		-command=>[\&MsgStats::plot,$self,$tw,$event,$prefix,$label,$X,$Y,0],
	);
	$m->add('command',
		-label=>'Holding CDF...',
		-underline=>0,
		-command=>[\&MsgStats::plot,$self,$tw,$event,$prefix,$label,$X,$Y,1],
	);
	$m->add('command',
		-label=>'Interarrival phase...',
		-underline=>0,
		-command=>[\&MsgStats::plot,$self,$tw,$event,$prefix,$label,$X,$Y,2],
	);
	$m->add('command',
		-label=>'Interarrival PDF...',
		-underline=>0,
		-command=>[\&MsgStats::plot,$self,$tw,$event,$prefix,$label,$X,$Y,3],
	);
	$m->add('command',
		-label=>'Interarrival CDF...',
		-underline=>0,
		-command=>[\&MsgStats::plot,$self,$tw,$event,$prefix,$label,$X,$Y,4],
	);
	$m->Popup(
		-popanchor=>'nw',
		-popover=>'cursor',
	);
}

#package MsgStats;
sub dircstat {
	my ($self,$tw,$row,$span,$event,$prefix,$label) = @_;
	my $p;
	my $del = sprintf("%7.2f", $self->{durs}->{$event}/(($p = $self->{pegs}->{$event})?$p:1));
	my $dur = sprintf("%12.2f", $self->{durs}->{$event} / $span);
	$tw->Entry(%entryright,
		-textvariable=>\$dur,
	)->grid(-row=>$$row,-column=>2,-sticky=>'ewns');
	$tw->Entry(%entryright,
		-textvariable=>\$self->{pegs}->{$event},
		-validatecommand=>[sub{
			my ($del,$dur,$self,$event,$row,$col,$old,$proposed,$index,@args) = @_;
			my $p;
			$$del = sprintf("%7.2f", $self->{durs}->{$event}/(($p = $self->{pegs}->{$event})?$p:1));
			my $span;
			if (ref $self eq 'Counts') {
				$span = 300;
			} else {
				$span = $main::endtime->{tv_sec}  - $main::begtime->{tv_sec}
				     + ($main::endtime->{tv_usec} - $main::begtime->{tv_usec})/1000000;
			}
			$$dur = sprintf("%12.2f", $self->{durs}->{$event}/$span);
			return 1;
		 },\$del,\$dur,$self,$event],
		-validate=>'all',
	)->grid(-row=>$$row,-column=>3,-sticky=>'ewns');
	my $e = $tw->Entry(%entryright,
		-textvariable=>\$del,
	)->grid(-row=>$$row,-column=>4,-sticky=>'ewns');
	my $X = $tw->toplevel->rootx;
	my $Y = $tw->toplevel->rooty;
	$tw->Button(
#		-command=>[\&MsgStats::dist,$self,$tw,$event,$prefix,$label,$X,$Y],
		-command=>[\&MsgStats::plotmenu,$self,$tw,$event,$prefix,$label,$X,$Y],
		-text=>'Plot',
#		-relief=>'flat',
#		-overrelief=>'raised',
		-pady=>0,
		-pady=>0,
	)->grid(-row=>$$row,-column=>5,-sticky=>'ewns');
	$$row++;
}

#package MsgStats;
sub addcstat {
	my ($self,$tw,$row,$span,$event,$label) = @_;
	for (my $dir = 0; $dir <= 20; $dir += 10) {
		my $prefix;
		if ($dir > 10) {
			$prefix = 'Total';
		} else {
			if ($self->{way} eq 'O') {
				$prefix = ($dir == 0) ? 'O/G' : 'I/C';
			} elsif ($self->{way} eq 'I') {
				$prefix = ($dir == 0) ? 'I/C' : 'O/G';
			} else {
				$prefix = ($dir == 0) ? 'Forward' : 'Reverse';
			}
		}
		if ($dir == 20) {
			$tw->Label(%labelright,
				-text=>$label,
			)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
		}
		$tw->Label(%labelright,
			-text=>$prefix,
		)->grid(-row=>$$row,-column=>1,-sticky=>'ewns');
		$self->dircstat($tw,$row,$span,$event+$dir,$prefix,$label);
	}
}

#package MsgStats;
sub cstat {
	my ($self,$canvas,$X,$Y) = @_;
	my $row = 0;
	my $tw;
	if ($tw = $self->{cstat}) {
		if ($tw->state eq 'iconic') {
			$tw->deiconify;
		} else {
			$tw->UnmapWindow;
		}
	} else {
		my $title = $self->identify." Call Statistics";
		$tw = $canvas->toplevel->Toplevel(
			-title=>$title,
		);
		$tw->group($canvas->toplevel);
		#$tw->transient($canvas->toplevel);
		$tw->iconimage('icon');
		$tw->iconname($title);
		$tw->resizable(0,0);
		$tw->positionfrom('user');
		$tw->geometry("+$X+$Y");
		$tw->protocol('WM_DELETE_WINDOW', [sub {
			my $self = shift;
			while (my ($k,$v) = each %{$self->{dist}}) {
				while (my ($l,$m) = each %{$v}) {
					if ($m) {
						delete $v->{$l};
						$m->destroy;
					}
				}
			}
			my $tw = $self->{cstat};
			delete $self->{cstat};
			$tw->destroy;
		},$self]);
		$self->{cstat} = $tw;

		my $span;
		if (ref $self eq 'Counts') {
			$span = 300;
		} else {
			$span = $main::endtime->{tv_sec}  - $main::begtime->{tv_sec}
			     + ($main::endtime->{tv_usec} - $main::begtime->{tv_usec})/1000000;
		}
		my $f = $tw->TFrame(%tframestyle,
			-label=>'Circuits:',
		)->pack(%tframepack);
		$f->Label(%labelright,
			-text=>'Defined circuits:',
		)->grid(-row=>$row,-column=>0,-sticky=>'ewns');
		$f->Entry(%entryright,
			-textvariable=>\$self->{ciccnt},
		)->grid(-row=>$row,-column=>1,-sticky=>'ewns');
		$f->Label(%labelright,
			-text=>'Active circuits:',
		)->grid(-row=>$row,-column=>2,-sticky=>'ewns');
		$f->Entry(%entryright,
			-textvariable=>\$self->{actcnt},
		)->grid(-row=>$row,-column=>3,-sticky=>'ewns');
		if (ref $self eq 'SSP' or ref $self eq 'SP') {
			$f->Label(%labelright,
				-text=>'Active O/G circuits:',
			)->grid(-row=>$row,-column=>4,-sticky=>'ewns');
			$f->Entry(%entryright,
				-textvariable=>\$self->{actog},
			)->grid(-row=>$row++,-column=>5,-sticky=>'ewns');
			$f->Label(%labelright,
				-text=>'Active I/C circuits:',
			)->grid(-row=>$row,-column=>4,-sticky=>'ewns');
			$f->Entry(%entryright,
				-textvariable=>\$self->{actic},
			)->grid(-row=>$row++,-column=>5,-sticky=>'ewns');
			$f->Label(%labelright,
				-text=>'Active 2/W circuits:',
			)->grid(-row=>$row,-column=>4,-sticky=>'ewns');
			$f->Entry(%entryright,
				-textvariable=>\$self->{act2w},
			)->grid(-row=>$row++,-column=>5,-sticky=>'ewns');
		}
		if (ref $self eq 'Relation' or ref $self eq 'Linkset') {
			$f->Label(%labelright,
				-text=>'Active forward circuits:',
			)->grid(-row=>$row,-column=>4,-sticky=>'ewns');
			$f->Entry(%entryright,
				-textvariable=>\$self->{actforw},
			)->grid(-row=>$row++,-column=>5,-sticky=>'ewns');
			$f->Label(%labelright,
				-text=>'Active reverse circuits:',
			)->grid(-row=>$row,-column=>4,-sticky=>'ewns');
			$f->Entry(%entryright,
				-textvariable=>\$self->{actrevs},
			)->grid(-row=>$row++,-column=>5,-sticky=>'ewns');
			$f->Label(%labelright,
				-text=>'Active bothway circuits:',
			)->grid(-row=>$row,-column=>4,-sticky=>'ewns');
			$f->Entry(%entryright,
				-textvariable=>\$self->{actboth},
			)->grid(-row=>$row++,-column=>5,-sticky=>'ewns');
		}
		if (ref $self eq 'Network') {
			$f->Label(%labelright,
				-text=>'Active one-way circuits:',
			)->grid(-row=>$row,-column=>4,-sticky=>'ewns');
			$f->Entry(%entryright,
				-textvariable=>\$self->{act1w},
			)->grid(-row=>$row++,-column=>5,-sticky=>'ewns');
			$f->Label(%labelright,
				-text=>'Active bothway circuits:',
			)->grid(-row=>$row,-column=>4,-sticky=>'ewns');
			$f->Entry(%entryright,
				-textvariable=>\$self->{act2w},
			)->grid(-row=>$row++,-column=>5,-sticky=>'ewns');
		}
		if ($self->{actcnt}) {
			$f = $tw->TFrame(%tframestyle,
				-label=>'Call stats:',
			)->pack(%tframepack);
			$row = 0;
			$f->Label(%labelcenter,
				-text=>'Occupancy',
			)->grid(-row=>$row,-column=>2,-sticky=>'ewns');
			$f->Label(%labelcenter,
				-text=>'Periods',
			)->grid(-row=>$row,-column=>3,-sticky=>'ewns');
			$f->Label(%labelcenter,
				-text=>'Duration',
			)->grid(-row=>$row,-column=>4,-sticky=>'ewns');
			$f->Label(%labelcenter,
				-text=>'Distribution',
			)->grid(-row=>$row++,-column=>5,-sticky=>'ewns');
			$self->addcstat($f,\$row,$span,CTS_IDLE,'Idle');
			$self->addcstat($f,\$row,$span,CTS_WAIT_ACM,'Setup');
			$self->addcstat($f,\$row,$span,CTS_WAIT_ANM,'Ringing');
			$self->addcstat($f,\$row,$span,CTS_ANSWERED,'Call');
			$self->addcstat($f,\$row,$span,CTS_SUSPENDED,'Suspension');
			$self->addcstat($f,\$row,$span,CTS_WAIT_RLC,'Release');
		}
	}
	$tw->update;
	$tw->MapWindow;
}

# -------------------------------------
package Properties;
use strict;
# -------------------------------------

#package Properties;
sub init {
	my ($self,@args) = @_;
	$self->{props} = undef;
}

#package Properties;
sub props {
	my ($self,$canvas,$X,$Y) = @_;
	my $row = 0;
	my $tw;

	if ($tw = $self->{props}) {
		if ($tw->state eq 'iconic') {
			$tw->deiconify;
		} else {
			$tw->UnmapWindow;
		}
	} else {
		my $title = $self->shortid." Properties";
		$tw = $canvas->toplevel->Toplevel(
			-title=>$title,
		);
		$tw->group($canvas->toplevel);
		#$tw->transient($canvas->toplevel);
		$tw->iconimage('icon');
		$tw->iconname($title);
		$tw->resizable(0,0);
		$tw->positionfrom('user');
		$tw->geometry("+$X+$Y");
		$tw->protocol('WM_DELETE_WINDOW', [sub {
			my $self = shift;
			my $tw = $self->{props};
			$self->{props} = undef;
			$tw->destroy;
		},$self]);
		$self->{props} = $tw;

		my $v = $self->identify;
		$tw->Label(%labelright,
			-text=>'Object type:',
		)->grid(-row=>$row,-column=>0,-sticky=>'ewns');
		$tw->Entry(%entryleft,
			-textvariable=>\$v,
		)->grid(-row=>$row++,-column=>1,-sticky=>'ewns');

		$self->fillprops($tw,\$row);
	}
	$tw->update;
	$tw->MapWindow;
}

# -------------------------------------
package Status;
use strict;
# -------------------------------------

#package Status;
sub init {
	my ($self,@args) = @_;
	$self->{statu} = undef;
}

#package Status;
sub status {
	my ($self,$canvas,$X,$Y) = @_;
	my $row = 0;
	my $tw;
	if ($tw = $self->{statu}) {
		if ($tw->state eq 'iconic') {
			$tw->deiconify;
		} else {
			$tw->UnmapWindow;
		}
	} else {
		my $title = $self->shortid." Status";
		$tw = $canvas->toplevel->Toplevel(
			-title=>$title,
		);
		$tw->group($canvas->toplevel);
		#$tw->transient($canvas->toplevel);
		$tw->iconimage('icon');
		$tw->iconname($title);
		$tw->resizable(0,0);
		$tw->positionfrom('user');
		$tw->geometry("+$X+$Y");
		$tw->protocol('WM_DELETE_WINDOW', [sub {
			my $self = shift;
			my $tw = $self->{statu};
			$self->{statu} = undef;
			$tw->destroy;
		},$self]);
		$self->{statu} = $tw;
		$self->fillstatus($tw,\$row);
	}
	$tw->update;
	$tw->MapWindow;
}

# -------------------------------------
package Clickable;
use strict;
# -------------------------------------

#package Clickable;
sub getmenu {
	my ($self,$m,$canvas,$X,$Y) = @_;
	my $ref = ref $self;
	my $len = length($ref) + 1;
	if (exists $self->{props}) {
		$m->add('command',
			#-accelerator=>'p',
			-command=>[\&Properties::props, $self, $canvas, $X, $Y],
			-label=>"$ref Properties...",
			-underline=>$len,
		);
	}
	if (exists $self->{statu}) {
		$m->add('command',
			#-accelerator=>'s',
			-command=>[\&Status::status, $self, $canvas, $X, $Y],
			-label=>"$ref Status...",
			-underline=>$len,
		);
	}
	if (exists $self->{logs}) {
		$m->add('command',
			#-accelerator=>'l',
			-command=>[\&Logging::showlog, $self, $canvas, $X, $Y],
			-label=>"$ref Logs...",
			-underline=>$len,
			-state=>(@{$self->{logs}} ? 'normal' : 'disabled'),
		);
	}
	if (exists $self->{incs}) {
		$m->add('command',
			#-accelerator=>'m',
			-command=>[\&MsgStats::stats, $self, $canvas, $X, $Y],
			-label=>'Message Statistics...',
			-underline=>0,
			-state=>($self->{incs}->{0}->{sus} + $self->{incs}->{1}->{sus} ? 'normal' : 'disabled'),
		);
	}
	if (exists $self->{ciccnt}) {
		$m->add('command',
			#-accelerator=>'c',
			-command=>[\&MsgStats::cstat, $self, $canvas, $X, $Y],
			-label=>'Call statistics...',
			-underline=>0,
			-state=>($self->{ciccnt} ? 'normal' : 'disabled'),
		);
	}
}

#package Clickable;
sub button3 {
	my ($canvas,$self,$X,$Y) = @_;
	my $ref = ref $self;
	my $m = $canvas->toplevel->Menu(
		-tearoff=>1,
		-title=>"$ref Menu",
		-type=>'normal',
	);
	$self->getmenu($m,$canvas,$X,$Y);
	$m->Popup(
		-popanchor=>'nw',
		-popover=>'cursor',
	);

}

# -------------------------------------
package Relation;
use strict;
use vars qw(@ISA);
@ISA = qw(MsgStats Logging Properties Status Clickable);
# -------------------------------------
# A relation is an association between signalling points that communicate with
# each other.  This object is used to track these interactions, primarily for
# identifying the role of nodes.
# -------------------------------------

use constant {
	RS_AVAILABLE => 0,
	RS_DEGRADED => 1,
	RS_CONGESTED_1 => 2,
	RS_CONGESTED_2 => 3,
	RS_CONGESTED_3 => 4,
	RS_UNAVAILABLE => 5,
};

my @rsoptions = (
	['Available'    => RS_AVAILABLE  ],
	['Degraded'     => RS_DEGRADED   ],
	['Congested'    => RS_CONGESTED_1],
	['Congested(2)' => RS_CONGESTED_2],
	['Congested(3)' => RS_CONGESTED_3],
	['Unavailable'  => RS_UNAVAILABLE],
);

my %relations;
my $relationno = 0;

#package Relation;
sub init {
	my ($self,$relationno,$nodea,$nodeb,@args) = @_;
	$self->MsgStats::init(@args);
	$self->Logging::init(@args);
	$self->Properties::init(@args);
	$self->Status::init(@args);
	$self->{key} = "$nodea->{pc},$nodeb->{pc}";
	$self->{state} = RS_AVAILABLE;
	$self->{statetext} = 'Available';
	$self->{cics} = {};
	$self->{ciccnt} = 0;
	$self->{actcnt} = 0;
	$self->{actforw} = 0;
	$self->{actrevs} = 0;
	$self->{actboth} = 0;
	$self->{slcs} = {};
	$self->{slccnt} = 0;
	$self->{nodea} = $nodea;
	$self->{nodeb} = $nodeb;
	$nodea->{relate}->{$nodeb->{pc}} = $self;
	$nodeb->{relate}->{$nodea->{pc}} = $self;
	my $xa = $self->{xa} = $nodea->{x};
	my $ya = $self->{ya} = $nodea->{y};
	my $xb = $self->{xb} = $nodeb->{x};
	my $yb = $self->{yb} = $nodeb->{y};
	$self->{x} = ($xa + $xb)/2;
	$self->{y} = ($ya + $yb)/2;
	$self->{fill} = 'grey';
	$self->{item} = $main::canvas->createLine($xa,$ya,$xb,$yb,
		-arrow=>'none',
		-capstyle=>'round',
		-fill=>$self->{fill},
		-joinstyle=>'round',
		-smooth=>0,
		-tags=>['relation'],
		-width=>1,
	);
	$main::canvas->bind($self->{item},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->lower('relation','node');
	$main::canvas->lower('relation','path');
	$main::mycanvas->addballoon($self->{item}, $self->identify);
	$main::top->{updatenow} = 1;
#	$main::canvas->idletasks;


}

#package Relation;
sub new {
	my ($type,$network,@args) = @_;
	my $self = {};
	bless $self,$type;
	$self->{network} = $network;
	$self->init(@args);
	$::statusbar->configure(-text=>"New ".$self->identify);
	return $self;
}

#package Relation;
sub get {
	my ($type,$nodea,$nodeb,@args) = @_;
	my $key = "$nodea->{pc},$nodeb->{pc}";
	return $relations{$key} if exists $relations{$key};
	my $self = {};
	bless $self, $type;
	$relationno = $relationno + 1;
	$relations{$key} = $self;
	$key = "$nodeb->{pc},$nodea->{pc}";
	$relations{$key} = $self; # place reverse entry too
	$self->init($relationno,$nodea,$nodeb,@args);
	return $self;
}

#package Relation;
sub identify {
	my $self = shift;
	my $id = "Relation ";
	$id .= "$self->{nodea}->{pcode}";
	$id .= " ($self->{nodea}->{pownr})" if $self->{nodea}->{pownr};
	$id .= ", $self->{nodeb}->{pcode}";
	$id .= " ($self->{nodeb}->{pownr})" if $self->{nodeb}->{pownr};
	return $id;
}

#package Relation;
sub shortid {
	my $self = shift;
	return "$self->{nodea}->{pcode}::$self->{nodeb}->{pcode}";
}

#package Relation;
sub add_forw { # from nodea to nodeb
	my ($self,$msg) = @_;
	my $si = $msg->{si};
	my $mt = $msg->{mt};
	if ($si == 5) {
		if ($mt == 0x10 || (0x12 <= $mt && $mt <= 0x1b) || $mt == 0x2a || $mt == 0x2b) {
			unless ($self->{xchg_isup}) {
				$self->{xchg_isup} = 1;
				$self->{reanalyze} = 1;
			}
		}
		$self->reanalyze if $self->{reanalyze};
		return;
	}
	if ($si == 3) {
		if ($mt == 0x09 || $mt == 0x11 || $mt == 0x13) { # udt,xudt,ludt
			unless ($self->{forw_tcap}) {
				$self->{forw_tcap} = 1;
				$self->{reanalyze} = 1;
			}
		}
		$self->reanalyze if $self->{reanalyze};
		return;
	}
	if ($si == 2 || $si == 1) {
		if ($mt == 0x11 || $mt == 0x12) { # sltm,slta
			unless ($self->{exch_sltm}) {
				$self->{exch_sltm} = 1;
				$self->{reanalyze} = 1;
			}
		}
		$self->reanalyze if $self->{reanalyze};
		return;
	}
}

#package Relation;
sub add_revs { # from nodeb to nodea
	my ($self,$msg) = @_;
	my $si = $msg->{si};
	my $mt = $msg->{mt};
	if ($si == 5) {
		if ($mt == 0x10 || (0x12 <= $mt && $mt <= 0x1b) || $mt == 0x2a || $mt == 0x2b) {
			unless ($self->{xchg_isup}) {
				$self->{xchg_isup} = 1;
				$self->{reanalyze} = 1;
			}
		}
		$self->reanalyze if $self->{reanalyze};
		return;
	}
	if ($si == 3) {
		if ($mt == 0x09 || $mt == 0x11 || $mt == 0x13) { # udt,xudt,ludt
			unless ($self->{revs_tcap}) {
				$self->{revs_tcap} = 1;
				$self->{reanalyze} = 1;
			}
		}
		$self->reanalyze if $self->{reanalyze};
		return;
	}
	if ($si == 2 || $si == 1) {
		if ($mt == 0x11 || $mt == 0x12) { # sltm,slta
			unless ($self->{xchg_sltm}) {
				$self->{xchg_sltm} = 1;
				$self->{reanalyze} = 1;
			}
		}
		$self->reanalyze if $self->{reanalyze};
		return;
	}
}

#package Relation;
sub add {
	my ($self,$msg) = @_;
	if ($msg->{si} == 5) {
		my $circuit = Circuit->get($self,$msg->{cic});
		$circuit->add_msg($msg);
	}
	if ($self->{key} eq "$msg->{opc},$msg->{dpc}") {
		$self->add_forw($msg);
		$self->inc($msg,'0');
		$self->{network}->inc($msg,'0');
		return;
	}
	if ($self->{key} eq "$msg->{dpc},$msg->{opc}") {
		$self->add_revs($msg);
		$self->inc($msg,'1');
		$self->{network}->inc($msg,'1');
		return;
	}
	print STDERR "error key=$self->{key}, opc=$msg->{opc}, dpc=$msg->{dpc}\n";
}

#package Relation;
sub reanalyze {
	my $self = shift;
	if ($self->{xchg_sltm}) {
		$self->{fill} = 'black';
		$main::canvas->itemconfigure($self->{item}, -fill=>$self->{fill});
		return;
	}
	if ($self->{xchg_isup}) {
		$self->{fill} = 'blue';
		$main::canvas->itemconfigure($self->{item}, -fill=>$self->{fill});
		return;
	}
	if ($self->{forw_tcap} && $self->{revs_tcap}) {
		$self->{fill} = 'blue';
		$main::canvas->itemconfigure($self->{item}, -fill=>$self->{fill});
		return;
	}
	if ($self->{forw_tcap}) {
		$self->{fill} = 'red';
		$main::canvas->itemconfigure($self->{item}, -fill=>$self->{fill});
		return;
	}
	if ($self->{revs_tcap}) {
		$self->{fill} = 'green';
		$main::canvas->itemconfigure($self->{item}, -fill=>$self->{fill});
		return;
	}
	$self->{fill} = 'gray';
	$main::canvas->itemconfigure($self->{item}, -fill=>$self->{fill});
	return;
	if ($self->{xchg_isup}) {
		if ($self->{forw_tcap}) {
			if ($self->{revs_tcap}) {
				if ($self->{xchg_sltm}) {
				} else {
				}
			} else {
				if ($self->{xchg_sltm}) {
				} else {
				}
			}
		} else {
			if ($self->{revs_tcap}) {
				if ($self->{xchg_sltm}) {
				} else {
				}
			} else {
				if ($self->{xchg_sltm}) {
				} else {
				}
			}
		}
	} else {
		if ($self->{forw_tcap}) {
			if ($self->{revs_tcap}) {
				if ($self->{xchg_sltm}) {
				} else {
				}
			} else {
				# SCP's originate but never terminate
				if ($self->{xchg_sltm}) {
				} else {
				}
			}
		} else {
			if ($self->{revs_tcap}) {
				# GTT functions never originate, just terminate
				if ($self->{xchg_sltm}) {
				} else {
				}
			} else {
				if ($self->{xchg_sltm}) {
				} else {
				}
			}
		}
	}
	delete $self->{reanalyze};
}

#package Relation;
sub move {
	my $self = shift;
	my $nodea = $self->{nodea};
	my $nodeb = $self->{nodeb};
	my $xa = $nodea->{x};
	my $ya = $nodea->{y};
	my $xb = $nodeb->{x};
	my $yb = $nodeb->{y};
	return if $xa == $self->{xa} &&
		  $ya == $self->{ya} &&
		  $xb == $self->{xb} &&
		  $yb == $self->{yb};
	$self->{cola} = $nodea->{col};
	$self->{rowa} = $nodea->{row};
	$self->{colb} = $nodeb->{col};
	$self->{rowb} = $nodeb->{row};
	$main::canvas->coords($self->{item},$xa,$ya,$xb,$yb);
	$self->{xa} = $xa;
	$self->{ya} = $ya;
	$self->{xb} = $xb;
	$self->{yb} = $yb;
	$self->{x} = ($xa + $xb)/2;
	$self->{y} = ($ya + $yb)/2;
}

#package Relation;
sub getmenu {
	my ($self,$m,$canvas,$X,$Y) = @_;
	shift->Clickable::getmenu(@_);
	$m->add('separator');
	my ($mc,$m3);
	$mc = $m->Menu(
		-tearoff=>1,
		-title=>'Links Menu',
	);
	foreach my $slc (sort {$a <=> $b} keys %{$self->{links}}) {
		my $link = $self->{links}->{$slc};
		$m3 = $mc->Menu(
			-tearoff=>1,
			-title=>"Link $slc Menu",
		);
		$link->getmenu($m3,$canvas,$X,$Y);
		$mc->add('cascade',
			-menu=>$m3,
			-label=>"Link $slc",
		);
	}
	$m->add('cascade',
		-menu=>$mc,
		-label=>'Links',
		-state=>((keys %{$self->{links}})?'normal':'disabled'),
	);
	$mc = $m->Menu(
		-tearoff=>1,
		-title=>'Circuits Menu',
	);
	foreach my $cic (sort {$a <=> $b} keys %{$self->{cics}}) {
		my $circuit;
		$m3 = $mc->Menu(
			-tearoff=>1,
			-title=>"Circuit $cic Menu",
		);
		$circuit = $self->{cics}->{$cic};
		$circuit->getmenu($m3,$canvas,$X,$Y) if $circuit;
		$mc->add('cascade',
			-menu=>$m3,
			-label=>"Circuit $cic",
		);
	}
	$m->add('cascade',
		-menu=>$mc,
		-label=>'Circuits',
		-state=>((keys %{$self->{cics}})?'normal':'disabled'),
	);
}

#package Relation;
sub fillprops {
	my ($self,$tw,$row) = @_;

	$tw->Label(%labelright,
		-text=>'SP A point code:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	my $pca = $self->{nodea}->{pcode};
	$pca .= " ($self->{nodea}->{pownr})" if $self->{nodea}->{pownr};
	$tw->Entry(%entryleft,
		-textvariable=>\$pca,
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'SP B point code:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	my $pcb = $self->{nodeb}->{pcode};
	$pcb .= " ($self->{nodeb}->{pownr})" if $self->{nodeb}->{pownr};
	$tw->Entry(%entryleft,
		-textvariable=>\$pcb,
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
}

#package Relation;
sub fillstatus {
	my ($self,$tw,$row) = @_;

	$tw->Label(%labelright,
		-text=>'Exchange SLTM:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Checkbutton(%buttonleft,
		-text=>'Exchanges SLTM',
		-variable=>\$self->{xchg_sltm},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'Exchange ISUP:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Checkbutton(%buttonleft,
		-text=>'Exchanges ISUP',
		-variable=>\$self->{xchg_isup},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'Forward TCAP:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Checkbutton(%buttonleft,
		-text=>'Forward TCAP',
		-variable=>\$self->{forw_tcap},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'Reverse TCAP:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Checkbutton(%buttonleft,
		-text=>'Reverse TCAP',
		-variable=>\$self->{revs_tcap},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'State:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Optionmenu(%optionleft,
		-options=>\@rsoptions,
		-variable=>\$self->{state},
		-textvariable=>\$self->{statetext},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	if ($self->{slccnt}) {
		$tw->Label(%labelright,
			-text=>'Signalling links:',
		)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
		$tw->Entry(%entryright,
			-textvariable=>\$self->{slccnt},
		)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	}
	if ($self->{ciccnt}) {
		$tw->Label(%labelright,
			-text=>'Defined circuits:',
		)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
		$tw->Entry(%entryright,
			-textvariable=>\$self->{ciccnt},
		)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
		if ($self->{actcnt}) {
			$tw->Label(%labelright,
				-text=>'Active circuits:',
			)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
			$tw->Entry(%entryright,
				-textvariable=>\$self->{actcnt},
			)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
		}
		if ($self->{actforw}) {
			$tw->Label(%labelright,
				-text=>'Active forward circuits:',
			)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
			$tw->Entry(%entryright,
				-textvariable=>\$self->{actforw},
			)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
		}
		if ($self->{actrevs}) {
			$tw->Label(%labelright,
				-text=>'Active reverse circuits:',
			)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
			$tw->Entry(%entryright,
				-textvariable=>\$self->{actrevs},
			)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
		}
		if ($self->{actboth}) {
			$tw->Label(%labelright,
				-text=>'Active bothway circuits:',
			)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
			$tw->Entry(%entryright,
				-textvariable=>\$self->{actboth},
			)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
		}
	}
}

#package Relation;
sub log {
	my ($self,$text) = @_;
	$self->Logging::log($text);
	$self->{'nodea'}->log($text);
	$self->{'nodeb'}->log($text);
}

# -------------------------------------
package Call;
use strict;
# -------------------------------------

#package Call;
sub new {
	my ($type,$circuit) = @_;
	my $self = {};
	bless $self,$type;
	$self->{circuit} = $circuit;
	$self->{msgs} = [];
	$self->{state} = 0;
	if ($circuit->{call}) {
		push @{$circuit->{calls}}, $circuit->{call};
	}
	$circuit->{call} = $self;
	return $self;
}

#package Call;
sub setstate {
	my ($self,$msg,$newstate) = @_;
	$self->{state} = $newstate;
}

#package Call;
sub add_msg {
	my ($self,$msg,$state) = @_;
	push @{$self->{msgs}}, $msg;
	$self->setstate($state);
}

#package Call;
sub clear {
	my ($self,$msg,$state) = @_;
	$self->{msgs} = [];
	$self->setstate($state);
}


# -------------------------------------
package Circuit;
use strict;
use vars qw(@ISA);
@ISA = qw(MsgStats Logging Properties Status Clickable);
# -------------------------------------

use constant {
	CTS_UNINIT	=> 0,
	CTS_IDLE	=> 1,
	CTS_WAIT_ACM	=> 2,
	CTS_WAIT_ANM	=> 3,
	CTS_ANSWERED	=> 4,
	CTS_SUSPENDED	=> 5,
	CTS_WAIT_RLC	=> 6,
	CTS_SEND_RLC	=> 7,
	CTS_COMPLETE	=> 8,
};

#package Circuit;
sub get {
	my ($type,$group,$cic,@args) = @_;
	return $group->{cics}->{$cic} if exists $group->{cics}->{$cic};
	my $self = {};
	bless $self,$type;
	$self->MsgStats::init(@args);
	$self->Logging::init(@args);
	$self->Properties::init(@args);
	$self->Status::init(@args);
	$self->{dir} = 0;
	$self->{cic} = $cic;
	$self->{group} = $group;
	$group->{cics}->{$cic} = $self;
	$group->{ciccnt} += 1;
	$group->{nodea}->{ciccnt} += 1;
	$group->{nodeb}->{ciccnt} += 1;
	$group->{network}->{ciccnt} += 1;
	$self->{active} = 0;
	$self->{call} = undef;
	$self->{calls} = [];
	$self->{state} = CTS_UNINIT;
	return $self;
}

#package Circuit
sub setstate {
	my ($self,$msg,$newstate,$newdir) = @_;
	return if $self->{state} == $newstate;
	my $oldstate = $self->{state};
	my $olddir = $self->{dir};
	# There are several states that mean anything
	# CTS_UNINIT
	# CTS_IDLE - idle
	# CTS_WAIT_ACM, CTS_WAIT_ANM - setup
	# CTS_ANSWERED - call
	# CTS_SUSPENDED - call or teardown
	# CTS_WAIT_RLC - teardown
	if ($oldstate == CTS_UNINIT) {
		$self->{group}->{actcnt} += 1;
		$self->{group}->{nodea}->{actcnt} += 1;
		$self->{group}->{nodeb}->{actcnt} += 1;
		$self->{group}->{network}->{actcnt} += 1;
		if ($newstate == CTS_WAIT_ACM) {
			$oldstate = CTS_IDLE;
		} elsif ($newstate == CTS_WAIT_ANM) {
			$oldstate = CTS_WAIT_ACM;
		} elsif ($newstate == CTS_ANSWERED) {
			$oldstate = CTS_WAIT_ANM;
		} elsif ($newstate == CTS_SUSPENDED) {
			$oldstate = CTS_ANSWERED;
		} elsif ($newstate == CTS_WAIT_RLC) {
			$oldstate = CTS_SUSPENDED;
		} elsif ($newstate == CTS_IDLE) {
			$oldstate = CTS_WAIT_RLC;
		}
		$self->{ts}->{$oldstate} = $main::begtime;
	}
	$self->{ts}->{$newstate + $newdir} = $msg->{hdr};
	$self->iat($newstate + $newdir, $msg->{hdr});
	$self->iat($newstate + 20, $msg->{hdr});
	$self->dur($oldstate + $olddir, $self->{ts}->{$oldstate + $olddir}, $msg->{hdr});
	$self->dur($oldstate + 20, $self->{ts}->{$oldstate + $olddir}, $msg->{hdr});
	$self->peg($newstate + $newdir, $msg->{hdr});
	$self->peg($newstate + 20, $msg->{hdr});
	delete $self->{ts}->{$oldstate + $olddir};
	$self->{state} = $newstate;
	$self->{dir} = $newdir;
}

#package Circuit
sub dur {
	my ($self,@args) = @_;
	$self->Stats::dur(@args);
	$self->{group}->dur(@args);
	$self->{group}->{nodea}->dur(@args);
	$self->{group}->{nodeb}->dur(@args);
	$self->{group}->{network}->dur(@args);
}

#package Circuit
sub iat {
	my ($self,@args) = @_;
	$self->Stats::iat(@args);
	$self->{group}->iat(@args);
	$self->{group}->{nodea}->iat(@args);
	$self->{group}->{nodeb}->iat(@args);
	$self->{group}->{network}->iat(@args);
}

#package Circuit;
sub peg {
	my ($self,@args) = @_;
	$self->Stats::peg(@args);
	$self->{group}->peg(@args);
	$self->{group}->{nodea}->peg(@args);
	$self->{group}->{nodeb}->peg(@args);
	$self->{group}->{network}->peg(@args);
}

#package Circuit;
sub end_of_call {
	my ($self,$call,$msg,$dir) = @_;
	$self->setstate($msg,CTS_IDLE,$dir);
	$call->add_msg($msg,CTS_IDLE);
	push @{$self->{calls}}, $call;
	$self->{call} = undef
}

#package Circuit;
sub clear_call {
	my ($self,$call,$msg,$dir) = @_;
	$self->setstate($msg,CTS_IDLE,$dir);
	$call->clear($msg,CTS_IDLE);
}

#package Circuit;
sub restart_call {
	my ($self,$call,$msg,$dir) = @_;
	$self->setstate($msg,CTS_IDLE,$dir);
	if (@{$call->{msgs}}) {
		push @{$self->{calls}}, $call;
		$self->{call} = undef;
	} else {
		$call->clear($msg,CTS_IDLE);
	}
}

#package Circuit;
sub add_msg {
	my ($self,$msg) = @_;
	my $mt = $msg->{mt};
	my $call;
	my $dir = $self->{dir};
	while (1) {
		unless ($call = $self->{call}) {
			$call = $self->{call} = Call->new($self);
		}
		if ($mt == 0x01) { # iam
			if ($self->{state} <= CTS_WAIT_ACM) {
				my $group = $self->{group};
				my $nodea = $group->{nodea};
				my $nodeb = $group->{nodeb};
				my $network = $group->{network};
				if ($msg->{opc} == $nodea->{pc}) {
					$dir = 0;
					if (!($self->{active} & 0x1)) {
						$self->{active} |= 0x1;
						if ($self->{active} & 0x2) {
							$group->{actboth} += 1;
							$nodea->{act2w} += 1;
							$nodeb->{act2w} += 1;
							$network->{act2w} += 1;
							$group->{actrevs} -= 1;
							$nodea->{actic} -= 1;
							$nodeb->{actog} -= 1;
							$network->{act1w} -= 1;
						} else {
							$group->{actforw} += 1;
							$nodea->{actog} += 1;
							$nodeb->{actic} += 1;
							$network->{act1w} += 1;
						}
					}
				} else {
					$dir = 10;
					if (!($self->{active} & 0x2)) {
						$self->{active} |= 0x2;
						if ($self->{active} & 0x1) {
							$group->{actboth} += 1;
							$nodea->{act2w} += 1;
							$nodeb->{act2w} += 1;
							$network->{act2w} += 1;
							$group->{actforw} -= 1;
							$nodea->{actog} -= 1;
							$nodeb->{actic} -= 1;
							$network->{act1w} -= 1;
						} else {
							$group->{actrevs} += 1;
							$nodea->{actic} += 1;
							$nodeb->{actog} += 1;
							$network->{act1w} += 1;
						}
					}
				}
				$self->setstate($msg,CTS_WAIT_ACM,$dir);
				last;
			}
			$self->restart_call($call,$msg,$dir);
			next;
		}
		if ($mt == 0x02) { # sam
			last;
		}
		if ($mt == 0x03) { # inr
			last;
		}
		if ($mt == 0x04) { # inf
			last;
		}
		if ($mt == 0x05) { # cot
			last;
		}
		if ($mt == 0x06 || $mt == 0xed) { # acm exm
			if ($self->{state} == CTS_WAIT_ACM) {
				$self->setstate($msg,CTS_WAIT_ANM,$dir);
				last;
			}
			return;
		}
		if ($mt == 0x07) { # con
			if ($self->{state} == CTS_WAIT_ANM) {
				$self->setstate($msg,CTS_ANSWERED,$dir);
				last;
			}
			return;
		}
		if ($mt == 0x08) { # fot
			last;
		}
		if ($mt == 0x09) { # anm
			if ($self->{state} == CTS_WAIT_ANM) {
				$self->setstate($msg,CTS_ANSWERED,$dir);
				last;
			}
			return;
		}
		if ($mt == 0x0c) { # rel
			if ($self->{state} > CTS_IDLE) {
				$self->setstate($msg,CTS_WAIT_RLC,$dir);
				last;
			}
			return;
		}
		if ($mt == 0x0d) { # sus
			if ($self->{state} == CTS_ANSWERED || $self->{state} == CTS_SUSPENDED) {
				$self->setstate($msg,CTS_SUSPENDED,$dir);
				last;
			}
			return;
		}
		if ($mt == 0x0e) { # res
			if ($self->{state} == CTS_ANSWERED || $self->{state} == CTS_SUSPENDED) {
				$self->setstate($msg,CTS_ANSWERED,$dir);
				last;
			}
			return;
		}
		if ($mt == 0x10) { # rlc
			if ($self->{state} == CTS_WAIT_RLC) {
				$self->end_of_call($call,$msg,$dir);
				return;
			}
			return;
		}
		if ($mt == 0x11) { # ccr
			$self->end_of_call($call,$msg,$dir);
			return;
		}
		if ($mt == 0x12) { # rsc
			if ($self->{state} > CTS_WAIT_ANM) {
				$self->end_of_call($call,$msg,$dir);
				return;
			}
			$self->clear_call($call,$msg,$dir);
			return;
		}
		if ($mt == 0x13) { # blo
			if ($self->{state} < CTS_WAIT_ANM) {
				$self->clear_call($call,$msg,$dir);
				return;
			}
			return;
		}
		if ($mt == 0x14) { # ubl
			return;
		}
		if ($mt == 0x15) { # bla
			if ($self->{state} < CTS_WAIT_ANM) {
				$self->clear_call($call,$msg,$dir);
				return;
			}
			return;
		}
		if ($mt == 0x16) { # uba
			return;
		}
		if ($mt == 0x17) { # grs
			if ($self->{state} > CTS_WAIT_ANM) {
				$self->end_of_call($call,$msg,$dir);
				return;
			}
			$self->clear_call($call,$msg,$dir);
			return;
		}
		if ($mt == 0x19) { # cgu
			return;
		}
		if ($mt == 0x1a) { # cgba
			if ($self->{state} < CTS_WAIT_ANM) {
				$self->clear_call($call,$msg,$dir);
				return;
			}
			return;
		}
		if ($mt == 0x1b) { # cgua
			return;
		}
		if ($mt == 0x1c) { # cmr
			return;
		}
		if ($mt == 0x1d) { # cmc
			return;
		}
		if ($mt == 0x1e) { # cmrj
			return;
		}
		if ($mt == 0x1f) { # far
			return;
		}
		if ($mt == 0x20) { # faa
			return;
		}
		if ($mt == 0x21) { # frj
			return;
		}
		if ($mt == 0x22) { # fad
			return;
		}
		if ($mt == 0x23) { # fai
			return;
		}
		if ($mt == 0x24) { # lpa
			last;
		}
		if ($mt == 0x25) { # csvq
			last;
		}
		if ($mt == 0x26) { # csvr
			last;
		}
		if ($mt == 0x27) { # drs
			last;
		}
		if ($mt == 0x28) { # pam
			last;
		}
		if ($mt == 0x29) { # gra
			if ($self->{state} > CTS_WAIT_ANM) {
				$self->end_of_call($call,$msg,$dir);
				return;
			}
			$self->clear_call($call,$msg,$dir);
			return;
		}
		if ($mt == 0x2a) { # cqm
			return;
		}
		if ($mt == 0x2b) { # cqr
			return;
		}
		if ($mt == 0x2c) { # cpg
			if ($self->{state} == CTS_WAIT_ACM || $self->{state} == CTS_WAIT_ANM) {
				return;
			}
			last;
		}
		if ($mt == 0x2d) { # usr
			return;
		}
		if ($mt == 0x2e) { # ucic
			$self->clear_call($call,$msg,$dir);
			return;
		}
		if ($mt == 0x2f) { # cfn
			if ($self->{state} < CTS_ANSWERED) {
				$self->clear_call($call,$msg,$dir);
				return;
			}
			last;
		}
		if ($mt == 0x30) { # olm
			return;
		}
		if ($mt == 0x31) { # crg
			return;
		}
		if ($mt == 0x32) { # nrm
			return;
		}
		if ($mt == 0x33) { # fac
			last;
		}
		if ($mt == 0x34) { # upt
			return;
		}
		if ($mt == 0x35) { # upa
			return;
		}
		if ($mt == 0x36) { # idr
			return;
		}
		if ($mt == 0x37) { # irs
			return;
		}
		if ($mt == 0x38) { # sgm
			last;
		}
		if ($mt == 0xe9) { # cra
			if ($self->{state} == CTS_WAIT_ACM) {
				$self->setstate($msg,CTS_WAIT_ACM,$dir);
				last;
			}
			return;
		}
		if ($mt == 0xea) { # crm
			if ($self->{state} != CTS_IDLE && $self->{state} != CTS_WAIT_ACM) {
				$self->end_of_call($call,$msg,$dir);
				return;
			}
			$self->setstate($msg,CTS_WAIT_ACM,$dir);
			last;
		}
		if ($mt == 0xeb) { # cvr
			return;
		}
		if ($mt == 0xec) { # cvt
			return;
		}
		if ($mt == 0xf8) { # non
			return;
		}
		if ($mt == 0xfc) { # llm
			return;
		}
		if ($mt == 0xfd) { # cak
			return;
		}
		if ($mt == 0xfe) { # tcm
			return;
		}
		if ($mt == 0xff) { # mcp
			return;
		}
		return;
	}
	$call->add_msg($msg, $self->{state});
	return;
}

#package Circuit;
sub identify {
	my $self = shift;
	my $group = $self->{group};
	my $id = "Circuit $self->{cic} ";
	$id .= "$group->{nodea}->{pcode}";
	$id .= " ($group->{nodea}->{pownr})" if $group->{nodea}->{pownr};
	$id .= ", $group->{nodeb}->{pcode}";
	$id .= " ($group->{nodeb}->{pownr})" if $group->{nodeb}->{pownr};
	return $id;
}

#package Circuit;
sub shortid {
	my $self = shift;
	my $group = $self->{group};
	return "$group->{nodea}->{pcode},$group->{nodeb}->{pcode}:$self->{cic}";
}

#package Circuit;
sub fillprops {
	my ($self,$tw,$row) = @_;

	$tw->Label(%labelright,
		-text=>'Circuit id code:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Entry(%entryright,
		-textvariable=>\$self->{cic},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	my $group = $self->{group};
	$tw->Label(%labelright,
		-text=>'SP A point code:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	my $pca = $group->{nodea}->{pcode};
	$pca .= " ($group->{nodea}->{pownr})" if $group->{nodea}->{pownr};
	$tw->Entry(%entrycenter,
		-textvariable=>\$pca,
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'SP B point code:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	my $pcb = $group->{nodeb}->{pcode};
	$pcb .= " ($group->{nodeb}->{pownr})" if $group->{nodeb}->{pownr};
	$tw->Entry(%entrycenter,
		-textvariable=>\$pcb,
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
}

#package Circuit;
sub fillstatus {
	my ($self,$tw,$row) = @_;

	$tw->Label(%labelright,
		-text=>'Active:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Entry(%entryleft,
		-textvariable=>\$self->{active},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
}

# -------------------------------------
package Linkset;
use strict;
use vars qw(@ISA);
@ISA = qw(Relation);
# -------------------------------------

use constant {
	COL_NOD => 6,
	COL_SSP => 5,
	COL_SCP => 4,
	COL_GTT => 3,
	COL_ADJ => 2,
};

use constant {
	LS_AVAILABLE => 0,
	LS_DEGRADED => 1,
	LS_UNAVAILABLE => 2,
};

#package Linkset;
sub init {
	my ($self,$nodea,$nodeb,@args) = @_;
	$self->{forw} = [];
	$self->{revs} = [];
	$self->{lstate} = LS_AVAILABLE;
	$self->{lstatetext} = 'Available';
}

#package Linkset;
sub new {
	my ($type,$network,@args) = @_;
	my $self = {};
	bless $self,$type;
	$self->{network} = $network;
	$self->init(@args);
	$::statusbar->configure(-text=>"New ".$self->identify);
	return $self;
}

#package Linkset;
sub reposition {
	my ($self,$node) = @_;
	my $col = Linkset::COL_ADJ;
	if ($node->{col} < 0) { $col = -$col; }
	$node->movesp($col,$node->{row});
}

#package Linkset;
sub xform {
	my ($type,$self) = @_;
	return if $self->{type} == 1;
	return if ref $self eq $type;
	bless $self,$type;
	$self->{fill} = 'black';
	$self->{width} = 2;
	$main::canvas->itemconfigure($self->{item},
		-fill=>$self->{file},
		-width=>$self->{width},
	);
	$main::canvas->bind($self->{item},'<ButtonPress-3>',[\&Relation::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::mycanvas->addballoon($self->{item}, $self->identify);
	$self->reposition($self->{nodea});
	$self->reposition($self->{nodeb});
	#$self->move; # nodes will move me
#	$main::canvas->idletasks;
	$main::top->{updatenow} = 1;
	$::statusbar->configure(-text=>"Discovered ".$self->identify);
}

#package Linkset;
sub getLink {
	my ($self,$nodea,$nodeb,$slc,@args) = @_;
	return $self->{links}->{$slc} if exists $self->{links}->{$slc};
	my $link = Link->new($self->{'network'},$nodea,$nodeb,$slc,@args);
	$self->{links}->{$slc} = $link;
	return $link;
}

#package Linkset;
sub move {
	my $self = shift;
	$self->Relation::move;
	foreach my $link (values %{$self->{links}}) {
		$link->move;
	}
}

#package Linkset;
sub identify {
	my $self = shift;
	my $id = "Linkset ";
	$id .= "$self->{nodea}->{pcode}";
	$id .= " ($self->{nodea}->{pownr})" if $self->{nodea}->{pownr};
	$id .= ", $self->{nodeb}->{pcode}";
	$id .= " ($self->{nodeb}->{pownr})" if $self->{nodeb}->{pownr};
	return $id;
}

#package Linkset;
sub shortid {
	my $self = shift;
	return "$self->{nodea}->{pcode}:$self->{nodeb}->{pcode}";
}

#package Linkset;
sub fillprops {
	my ($self,$tw,$row) = @_;

	$tw->Label(%labelright,
		-text=>'SP A point code:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	my $pca = $self->{nodea}->{pcode};
	$pca .= " ($self->{nodea}->{pownr})" if $self->{nodea}->{pownr};
	$tw->Entry(%entrycenter,
		-textvariable=>\$pca,
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'SP B point code:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	my $pcb = $self->{nodeb}->{pcode};
	$pcb .= " ($self->{nodeb}->{pownr})" if $self->{nodeb}->{pownr};
	$tw->Entry(%entrycenter,
		-textvariable=>\$pcb,
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
}

#package Linkset;
sub fillstatus {
	my ($self,$tw,$row) = @_;

	$tw->Label(%labelright,
		-text=>'Exchange SLTM',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Checkbutton(%buttonleft,
		-text=>'Exchanges SLTM',
		-variable=>\$self->{xchg_sltm},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'Exchange ISUP:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Checkbutton(%buttonleft,
		-text=>'Exchanges ISUP',
		-variable=>\$self->{xchg_isup},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'Forward TCAP',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Checkbutton(%buttonleft,
		-text=>'Forward TCAP',
		-variable=>\$self->{forw_tcap},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'Reverse TCAP',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Checkbutton(%buttonleft,
		-text=>'Reverse TCAP',
		-variable=>\$self->{revs_tcap},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	if ($self->{slccnt}) {
		$tw->Label(%labelright,
			-text=>'Signalling links:',
		)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
		$tw->Entry(%entryright,
			-textvariable=>\$self->{slccnt},
		)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	}
	if ($self->{ciccnt}) {
		$tw->Label(%labelright,
			-text=>'Defined circuits:',
		)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
		$tw->Entry(%entryright,
			-textvariable=>\$self->{ciccnt},
		)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
		if ($self->{actcnt}) {
			$tw->Label(%labelright,
				-text=>'Active circuits:',
			)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
			$tw->Entry(%entryright,
				-textvariable=>\$self->{actcnt},
			)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
		}
		if ($self->{actforw}) {
			$tw->Label(%labelright,
				-text=>'Active forward circuits:',
			)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
			$tw->Entry(%entryright,
				-textvariable=>\$self->{actforw},
			)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
		}
		if ($self->{actrevs}) {
			$tw->Label(%labelright,
				-text=>'Active reverse circuits:',
			)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
			$tw->Entry(%entryright,
				-textvariable=>\$self->{actrevs},
			)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
		}
		if ($self->{actboth}) {
			$tw->Label(%labelright,
				-text=>'Active bothway circuits:',
			)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
			$tw->Entry(%entryright,
				-textvariable=>\$self->{actboth},
			)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
		}
	}
}

# -------------------------------------
package Link;
use strict;
use vars qw(@ISA);
@ISA = qw(MsgStats Logging Properties Status Clickable);
# -------------------------------------

use constant {
	LK_INSERVICE => 0,
	LK_BUSY => 1,
	LK_OUTOFSERVICE => 2,
};

#package Link;
sub init {
	my ($self,$nodea,$nodeb,$slc,@args) = @_;
	$self->MsgStats::init(@args);
	$self->Logging::init(@args);
	$self->Properties::init(@args);
	$self->Status::init(@args);
	$self->{nodea} = $nodea;
	$self->{nodeb} = $nodeb;
	$self->{slc} = $slc;
	$self->{state} = LK_INSERVICE;
	$self->{statetext} = 'In Service';
	$self->{pathforw} = undef;
	$self->{pathrevs} = undef;
}

#package Link;
sub new {
	my ($type,$network,@args) = @_;
	my $self = {};
	bless $self,$type;
	$self->{network} = $network;
	$self->init(@args);
	$::statusbar->configure(-text=>"New ".$self->identify);
	return $self;
}

#package Link;
sub addPathForw {
	my ($self,$path) = @_;
	$self->{pathforw} = $path;
}

#package Link;
sub addPathRevs {
	my ($self,$path) = @_;
	$self->{pathrevs} = $path;
}

#package Link;
sub addPath {
	my ($self,$path) = @_;
	if ($path->{nodea}->{pc} == $self->{nodea}->{pc}) {
		$self->addPathForw($path);
	} else {
		$self->addPathRevs($path);
	}
}

#package Link;
sub add {
	my ($self,$msg) = @_;
	if ($msg->{'opc'} == $self->{'nodea'}->{'pc'}) {
		$self->inc($msg,'0');
	} else {
		$self->inc($msg,'1');
	}
}

#package Link;
sub move {
	my $self = shift;
	my $path;
	if ($path = $self->{pathforw}) {
		$path->move;
	}
	if ($path = $self->{pathrevs}) {
		$path->move;
	}
}

#package Link;
sub identify {
	my $self = shift;
	my $id = "Link $self->{slc} ";
	$id .= "$self->{nodea}->{pcode}";
	$id .= " ($self->{nodea}->{pownr})" if $self->{nodea}->{pownr};
	$id .= ", $self->{nodeb}->{pcode}";
	$id .= " ($self->{nodeb}->{pownr})" if $self->{nodeb}->{pownr};
	return $id;
}

#package Link;
sub shortid {
	my $self = shift;
	return "$self->{slc}:$self->{nodea}->{pcode},$self->{nodeb}->{pcode}";
}

#package Link;
sub getmenu {
	my ($self,$m,$canvas,$X,$Y) = @_;
	shift->Clickable::getmenu(@_);
	$m->add('separator');
	my ($path,$mc);
	$path = $self->{pathforw};
	$mc = $m->Menu(
		-tearoff=>1,
		-title=>'Forward path menu',
	);
	$path->getmenu($mc,$canvas,$X,$Y) if $path;
	$m->add('cascade',
		-menu=>$mc,
		-label=>'Forward path',
		-state=>($path?'normal':'disabled'),
	);
	$path = $self->{pathrevs};
	$mc = $m->Menu(
		-tearoff=>1,
		-title=>'Revers path menu',
	);
	$path->getmenu($mc,$canvas,$X,$Y) if $path;
	$m->add('cascade',
		-menu=>$mc,
		-label=>'Reverse path',
		-state=>($path?'normal':'disabled'),
	);
}

#package Link;
sub fillprops {
	my ($self,$tw,$row) = @_;
}

#package Link;
sub fillstatus {
	my ($self,$tw,$row) = @_;
}

# -------------------------------------
package Route;
use strict;
use vars qw(@ISA);
@ISA = qw(MsgStats Logging Properties Status Clickable);
# -------------------------------------

use constant {
	RT_AVAILABLE => 0,
	RT_RESTRICTED => 1,
	RT_PROHIBITED => 2,
};

my @rtoptions = (
	['Available'  => RT_AVAILABLE ],
	['Restricted' => RT_RESTRICTED],
	['Prohibited' => RT_PROHIBITED],
);

#package Route;
sub new {
	my ($type,$path,$side,$node,@args) = @_;
	my $self = {};
	bless $self, $type;
	$self->MsgStats::init(@args);
	$self->Logging::init(@args);
	$self->Properties::init(@args);
	$self->Status::init(@args);
	$self->{state} = RT_AVAILABLE;
	$self->{statetext} = 'Available';
	$self->{path} = $path;
	$self->{side} = $side;
	$self->{node} = $node;
	$node->{routes}->{$path->{ppa}} = $self;
	$path->{routes}->{$node->{pc}} = $self;
	my ($cola,$rowa,$colb,$rowb);
	if ($side eq 'a') {
		$cola = $self->{cola} = $node->{col};
		$rowa = $self->{rowa} = $node->{row};
		$colb = $self->{colb} = $path->{cola};
		$rowb = $self->{rowb} = $path->{rowa};
	} else {
		$cola = $self->{cola} = $path->{colb};
		$rowa = $self->{rowa} = $path->{rowb};
		$colb = $self->{colb} = $node->{col};
		$rowb = $self->{rowb} = $node->{row};
	}
	my $mc = $main::mycanvas;
	my $xa = $self->{xa} = $mc->colpos($cola);
	my $ya = $self->{ya} = $mc->rowpos($rowa);
	my $xb = $self->{xb} = $mc->colpos($colb);
	my $yb = $self->{yb} = $mc->rowpos($rowb);
	$self->{x} = ($xa + $xb)/2;
	$self->{y} = ($ya + $yb)/2;
	$self->{color} = 'gray';
	my $c = $main::canvas;
	$self->{item} = $c->createLine($xa,$ya,$xb,$yb,
		-arrow=>'last',
		-capstyle=>'round',
		-fill=>$self->{color},
		-joinstyle=>'round',
		-smooth=>0,
		-tags=>['route'],
		-width=>1,
	);
	$c->bind($self->{item},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$c->traceVariable(\$self->{state},'w'=>[\&Route::tracestate,$self]);
	$c->traceVariable(\$self->{color},'w'=>[\&Route::tracecolor,$self]);
	$c->lower('route','path');
	$c->lower('route','node');
	$mc->addballoon($self->{item}, $self->identify);
	$main::top->{updatenow} = 1;
#	$main::canvas->idletasks;
	$::statusbar->configure(-text=>"New ".$self->identify);
	return $self;
}

sub DESTROY {
	my $self = shift;
	$main::canvas->traceVdelete(\$self->{state});
	$main::canvas->traceVdelete(\$self->{color});
}

#package Route;
sub tracestate {
	my ($ind,$val,$op,$self) = @_;
	if ($op eq 'w') {
		if ($val == RT_AVAILABLE) {
			$self->{color} = 'gray';
		} elsif ($val == RT_RESTRICTED) {
			$self->{color} = 'orange';
		} elsif ($val == RT_PROHIBITED) {
			$self->{color} = 'red';
		}
		$self->{node}->updatestate;
	}
	return $val;
}

#package Route;
sub tracecolor {
	my ($ind,$val,$op,$self) = @_;
	if ($op eq 'w') {
		$main::canvas->itemconfigure($self->{item},
			-fill=>$val,
		);
	}
	return $val;
}

#package Route;
sub identify {
	my $self = shift;
	my $id = "Route ";
	$id .= "($self->{path}->{card}:$self->{path}->{span}:$self->{path}->{slot})";
	if ($self->{side} eq 'a') {
		$id .= " <- ";
	} else {
		$id .= " -> ";
	}
	$id .= "$self->{node}->{pcode}";
	$id .= " ($self->{node}->{pownr})" if $self->{node}->{pownr};
	return $id;
}

#package Route;
sub shortid {
	my $self = shift;
	my $id = "($self->{path}->{card}:$self->{path}->{span}:$self->{path}->{slot})";
	if ($self->{side} eq 'a') {
		$id .= "<-";
	} else {
		$id .= "->";
	}
	$id .= "($self->{node}->{pcode})";
	return $id;
}

#package Route;
sub move {
	my $self = shift;
	my $node = $self->{node};
	my $path = $self->{path};
	my $side = $self->{side};
	my ($xa,$ya,$xb,$yb);
	if ($side eq 'a') {
		$xa = $node->{x};
		$ya = $node->{y};
		$xb = $path->{xa};
		$yb = $path->{ya};
	} else {
		$xa = $path->{xb};
		$ya = $path->{yb};
		$xb = $node->{x};
		$yb = $node->{y};
	}
	return if $xa == $self->{xa} &&
		  $ya == $self->{ya} &&
		  $xb == $self->{xb} &&
		  $yb == $self->{yb};
	if ($side eq 'a') {
		$self->{cola} = $node->{col};
		$self->{rowa} = $node->{row};
		$self->{colb} = $path->{cola};
		$self->{rowb} = $path->{rowa};
	} else {
		$self->{cola} = $path->{colb};
		$self->{rowa} = $path->{rowb};
		$self->{colb} = $node->{col};
		$self->{rowb} = $node->{row};
	}
	$main::canvas->coords($self->{item},$xa,$ya,$xb,$yb);
	$self->{xa} = $xa;
	$self->{ya} = $ya;
	$self->{xb} = $xb;
	$self->{yb} = $yb;
	$self->{x} = ($xa + $xb)/2;
	$self->{y} = ($ya + $yb)/2;
}

#package Route;
sub fillprops {
	my ($self,$tw,$row) = @_;

	$tw->Label(%labelright,
		-text=>'Signalling path:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Entry(%entryleft,
		-text=>"$self->{card}:$self->{span}:$self->{slot}",
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'Signalling point:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	my $pcode = $self->{node}->{pcode};
	$pcode .= " ($self->{node}->{pwonr})" if $self->{node}->{pownr};
	$tw->Entry(%entryleft,
		-textvariable=>\$pcode,
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
}

#package Route;
sub fillstatus {
	my ($self,$tw,$row) = @_;

	$tw->Label(%labelright,
		-text=>'Status:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Optionmenu(%optionleft,
		-options=>\@rtoptions,
		-variable=>\$self->{state},
		-textvariable=>\$self->{statetext},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
}

# -------------------------------------
package SP;
use strict;
use vars qw(@ISA);
@ISA = qw(MsgStats Logging Properties Status Clickable);
# -------------------------------------

my %nodes;
my $nodeno = 0;

use constant {
	COL_NOD => 6,
	COL_SSP => 5,
	COL_SCP => 4,
	COL_GTT => 3,
	COL_ADJ => 2,
};
use constant {
	SP_AVAILABLE => 0,
	SP_DEGRADED => 1,
	SP_UNAVAILABLE => 2,
};
my @spoptions = (
	['Available'	=> SP_AVAILABLE  ],
	['Degraded'	=> SP_DEGRADED	 ],
	['Unavailable'	=> SP_UNAVAILABLE],
);

#package SP;
sub init {
	my ($self,$nodeno,$pc,$path,$side,$way,@args) = @_;
	$self->MsgStats::init(@args);
	$self->Logging::init(@args);
	$self->Properties::init(@args);
	$self->Status::init(@args);
	$self->{pc} = $pc;
	$self->{rt} = $path->{rt};
	$self->{rttext} = $path->{rttext};
	$self->{side} = $side;
	$self->{way} = $way;
	$self->{state} = SP_AVAILABLE;
	$self->{statetext} = 'Available';
	$self->{ciccnt} = 0;
	$self->{actcnt} = 0;
	$self->{actog} = 0;
	$self->{actic} = 0;
	$self->{act2w} = 0;
	$self->{tqueries} = {};
	$self->{circuits} = {};
	$self->{responds} = {};
	$self->{routes} = {}; # routes that term or orig here
	$self->{relate} = {}; # relations in which this is a node
	my $x;
	if ($side < 0) {
		$x = $main::mycanvas->colpos(0 - COL_NOD);
		$self->{col} = 0 - COL_NOD;
	} else {
		$x = $main::mycanvas->colpos(0 + COL_NOD);
		$self->{col} = 0 + COL_NOD;
	}
	my $y = $main::mycanvas->rowpos(0);
	$self->{row} = 0;
	$self->{x} = $x;
	$self->{y} = $y;
	$self->{color} = 'white';
	$self->{item} = $main::canvas->createOval(
		$x-33,$y-33,$x+33,$y+33,
		-fill=>$self->{color},
		-outline=>'blue',
		-width=>2,
		-tags=>['node'],
	);
	$main::canvas->bind($self->{item},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->raise('node','path');
	$self->{scri} = $main::canvas->createLine(
		$x-23,$y-23,$x+23,$y-23,$x+23,$y+23,$x-23,$y+23,$x-23,$y-23,
		-arrow=>'none',
		-capstyle=>'round',
		-fill=>'gray',
		-joinstyle=>'round',
		-smooth=>0,
		-tags=>['scri'],
		-width=>1,
	);
	$main::canvas->bind($self->{scri},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->raise('scri','node');
	$self->{pcode} = main::pcstring($pc);
	$self->{lownr} = main::pcowner($pc,1);
	if ($self->{pownr} = main::pcowner($pc,0)) {
		$self->{ownr} = $main::canvas->createText($x,$y+15,
			-anchor=>'center',
			-fill=>'black',
			-justify=>'center',
			-text=>$self->{pownr},
			-tags=>['ownr'],
		);
		$main::canvas->bind($self->{ownr},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
		$main::canvas->raise('ownr','scri');
	}
	$self->{ttxt} = $main::canvas->createText($x,$y-15,
		-anchor=>'center',
		-fill=>'black',
		-justify=>'center',
		-text=>'SP',
		-tags=>['text'],
	);
	$main::canvas->bind($self->{ttxt},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->raise('ttxt','scri');
	$self->{text} = $main::canvas->createText($x,$y,
		-anchor=>'center',
		-fill=>'black',
		-justify=>'center',
		-text=>$self->{pcode},
		-tags=>['text'],
	);
	$main::canvas->raise('text','scri');
	$main::canvas->bind($self->{text},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->traceVariable(\$self->{state},'w'=>[\&SP::tracestate,$self]);
	$main::canvas->traceVariable(\$self->{color},'w'=>[\&SP::tracecolor,$self]);
	$main::mycanvas->addballoon($self->{item}, $self->identify,
				    $self->{scri}, $self->identify,
				    $self->{ttxt}, $self->identify,
				    $self->{text}, $self->identify);
	$self->{network}->regroupsps;
	$main::top->{updatenow} = 1;
#	$main::canvas->idletasks;
}

sub DESTROY {
	my $self = shift;
	$main::canvas->traceVdelete(\$self->{state});
}

#package SP;
sub tracestate {
	my ($ind,$val,$op,$self) = @_;
	if ($op eq 'w') {
		if ($val == SP_AVAILABLE) {
			$self->{color} = 'white';
		} elsif ($val == SP_DEGRADED) {
			$self->{color} = 'orange';
		} elsif ($val == SP_UNAVAILABLE) {
			$self->{color} = 'red';
		}
	}
	return $val;
}

#package SP;
sub tracecolor {
	my ($ind,$val,$op,$self) = @_;
	if ($op eq 'w') {
		$main::canvas->itemconfigure($self->{item},-fill=>$val);
	}
	return $val;
}

#package SP;
sub updatestate {
	my $self = shift;
	my ($avail,$degra,$unava) = (0,0);
	foreach my $route (values %{$self->{routes}}) {
		my $rstate = $route->{'state'};
		if ($rstate == Route::RT_AVAILABLE) {
			$avail++;
		} elsif ($rstate == Route::RT_RESTRICTED) {
			$degra++;
		} elsif ($rstate == Route::RT_PROHIBITED) {
			$unava++;
		}
	}
	if ($avail == 0 && $degra == 0 && $unava >= 0) {
		$self->{state} = SP_UNAVAILABLE;
	} elsif ($degra + $unava > 0) {
		$self->{state} = SP_DEGRADED;
	} else {
		$self->{state} = SP_AVAILABLE;
	}
}

#package SP;
sub new {
	my ($type,$network,@args) = @_;
	my $self = {};
	bless $self,$type;
	$self->{network} = $network;
	$self->init(@args);
	$::statusbar->configure(-text=>"New ".$self->identify);
	return $self;
}

#package SP;
sub get {
	my ($type,$pc,@args) = @_;
	return $SP::nodes{$pc} if exists $SP::nodes{$pc};
	my $self = {};
	bless $self, $type;
	$SP::nodes{$pc} = $self;
	$nodeno = $nodeno + 1;
	$self->init($nodeno,$pc,@args);
	return $self;
}

#package SP;
sub identify {
	my $self = shift;
	my $ref = ref $self;
	my $id = "$ref $self->{pcode}";
	$id .= " ($self->{pownr})" if $self->{pownr};
	return $id;
}

#package SP;
sub shortid {
	my $self = shift;
	my $ref = ref $self;
	return "$ref($self->{pcode})";
}

#package SP;
sub add_orig {
	my ($self,$msg) = @_;
	$self->inc($msg,'0');
	my $si = $msg->{si};
	my $mt = $msg->{mt};
	if ($si == 5) {
		if ($mt == 0x10 || (0x12 <= $mt && $mt <= 0x1b) || $mt == 0x2a || $mt == 0x2b) {
			unless ($self->{xchg_isup}) {
				$self->{xchg_isup} = 1;
				$self->{reanalyze} = 1;
			}
			$self->{circuits}->{$msg->{dpc}} = 1;
		}
		$self->reanalyze if $self->{reanalyze};
		return;
	}
	if ($si == 3) {
		if ($mt == 0x09 || $mt == 0x11 || $mt == 0x13) { # udt,xudt,ludt
			unless ($self->{orig_tcap}) {
				$self->{orig_tcap} = 1;
				$self->{reanalyze} = 1;
			}
			$self->{tqueries}->{$msg->{dpc}} = 1;
		}
		$self->reanalyze if $self->{reanalyze};
		return;
	}
	if ($si == 2 || $si == 1) {
		if ($mt == 0x11 || $mt == 0x12) { # sltm,slta
			unless ($self->{exch_sltm}) {
				$self->{exch_sltm} = 1;
				$self->{reanalyze} = 1;
			}
			$self->{adjacent}->{$msg->{dpc}} = 1;
		}
		$self->reanalyze if $self->{reanalyze};
		return;
	}
}

#package SP;
sub add_term {
	my ($self,$msg) = @_;
	$self->inc($msg,'1');
	my $si = $msg->{si};
	my $mt = $msg->{mt};
	if ($si == 5) {
		if ($mt == 0x10 || (0x12 <= $mt && $mt <= 0x1b) || $mt == 0x2a || $mt == 0x2b) {
			unless ($self->{xchg_isup}) {
				$self->{xchg_isup} = 1;
				$self->{reanalyze} = 1;
			}
			$self->{circuits}->{$msg->{opc}} = 1;
		}
		$self->reanalyze if $self->{reanalyze};
		return;
	}
	if ($si == 3) {
		if ($mt == 0x09 || $mt == 0x11 || $mt == 0x13) { # udt,xudt,ludt
			unless ($self->{term_tcap}) {
				$self->{term_tcap} = 1;
				$self->{reanalyze} = 1;
			}
			$self->{responds}->{$msg->{opc}} = 1;
		}
		$self->reanalyze if $self->{reanalyze};
		return;
	}
	if ($si == 2 || $si == 1) {
		if ($mt == 0x11 || $mt == 0x12) { # sltm,slta
			unless ($self->{xchg_sltm}) {
				$self->{xchg_sltm} = 1;
				$self->{reanalyze} = 1;
			}
			$self->{adjacent}->{$msg->{opc}} = 1;
		}
		$self->reanalyze if $self->{reanalyze};
		return;
	}
}

use constant {
	N_UNKNOWN => 0, # not yet identified
	N_GTT_CC  => 1, # GTT capability code
	N_SCP_DB  => 2, # SCP database
	N_SSP_TA  => 3, # SSP transaction alias
	N_SSP_AP  => 4, # SSP alias point code
	N_SSP_PP  => 5, # SSP primary point code
	N_SSP_NT  => 6, # SSP w/o TCAP
	N_SSP_WT  => 7, # SSP w/ TCAP
	N_STP_NG  => 8, # STP w/o GTT
	N_STP_WG  => 9, # STP w/ GTT
};

#package SP;
sub reanalyze {
	my $self = shift;
	my $col = abs($self->{col});
	my $row = $self->{row};
	if ($self->{xchg_sltm}) {
		$col = COL_ADJ;
	} elsif ($self->{xchg_isup} || ($self->{orig_tcap} && $self->{term_tcap})) {
		$col = COL_SSP;
	} elsif ($self->{orig_tcap} && !$self->{term_tcap}) {
		$col = COL_SCP;
	} elsif (!$self->{orig_tcap} && $self->{term_tcap}) {
		$col = COL_GTT;
	} 
	if (abs($self->{col}) != $col) {
		if ($self->{col} < 0) {
			$col = 0 - $col;
		}
		$self->movesp($col,$row);
		$self->{network}->regroupsps;
		$main::top->{updatenow} = 1;
#		$main::canvas->idletasks;
	}
	if ($self->{xchg_isup} || ($self->{orig_tcap} && $self->{term_tcap})) {
		SSP->xform($self);
	} elsif ($self->{orig_tcap} && !$self->{term_tcap}) {
		SCP->xform($self);
	} elsif (!$self->{orig_tcap} && $self->{term_tcap}) {
		GTT->xform($self);
	} elsif ($self->{xchg_sltm}) {
		STP->xform($self);
	}
	if ($self->{xchg_isup}) {
		if ($self->{orig_tcap}) {
			if ($self->{term_tcap}) {
				if ($self->{xchg_sltm}) {
				} else {
				}
			} else {
				if ($self->{xchg_sltm}) {
				} else {
				}
			}
		} else {
			if ($self->{term_tcap}) {
				if ($self->{xchg_sltm}) {
				} else {
				}
			} else {
				if ($self->{xchg_sltm}) {
				} else {
				}
			}
		}
	} else {
		if ($self->{orig_tcap}) {
			if ($self->{term_tcap}) {
				if ($self->{xchg_sltm}) {
				} else {
				}
			} else {
				# SCP's originate but never terminate
				if ($self->{xchg_sltm}) {
				} else {
				}
			}
		} else {
			if ($self->{term_tcap}) {
				# GTT functions never originate, just terminate
				if ($self->{xchg_sltm}) {
				} else {
				}
			} else {
				if ($self->{xchg_sltm}) {
				} else {
				}
			}
		}
	}
	delete $self->{reanalyze};
}

#package SP;
sub swap {
	my $self = shift;
	$self->movesp(-$self->{col},$self->{row});
}

#package SP;
sub movesp {
	my ($self,$col,$row) = @_;
	#return if $col == $self->{col} && $row == $self->{row};
	my $newx = $main::mycanvas->colpos($col);
	my $newy = $main::mycanvas->rowpos($row);
	my $deltax = $newx - $self->{x};
	my $deltay = $newy - $self->{y};
	if ($deltax or $deltay) {
		$main::canvas->move($self->{item},$deltax,$deltay);
		$main::canvas->move($self->{scri},$deltax,$deltay);
		$main::canvas->move($self->{ttxt},$deltax,$deltay);
		$main::canvas->move($self->{ownr},$deltax,$deltay) if $self->{ownr};
		$main::canvas->move($self->{text},$deltax,$deltay);
	}
	$self->{x} = $newx;
	$self->{y} = $newy;
	$self->{col} = $col;
	$self->{row} = $row;
	if ($deltax or $deltay) {
		foreach my $r (values %{$self->{routes}}) { $r->move; }
		foreach my $r (values %{$self->{relate}}) { $r->move; }
	}
}

#package SP;
sub getmenu {
	my ($self,$m,$canvas,$X,$Y) = @_;
	shift->Clickable::getmenu(@_);
	if (keys %{$self->{relate}}) {
		$m->add('separator');
		foreach my $pc (sort {$a <=> $b} keys %{$self->{relate}}) {
			my $relation = $self->{relate}->{$pc};
			my $node;
			if ($relation->{nodea}->{pc} == $self->{pc}) {
				$node = $relation->{nodeb};
			} else {
				$node = $relation->{nodea};
			}
			my $mc = $m->Menu(
				-tearoff=>1,
				-title=>'Routeset to '.$node->shortid.' Menu',
			);
			$relation->getmenu($mc,$canvas,$X,$Y);
			$m->add('cascade',
				-menu=>$mc,
				-label=>'Routeset to '.$node->shortid,
			);
		}
	}
}

#package SP;
sub fillprops {
	my ($self,$tw,$row) = @_;

	$tw->Label(%labelright,
		-text=>'Point code type:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Optionmenu(%optionleft,
		-options=>\@Path::rloptions,
		-variable=>\$self->{rt},
		-textvariable=>\$self->{rttext},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'Point code:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Entry(%entryleft,
		-textvariable=>\$self->{pcode},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'Point code owner:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Entry(%entryinput,
		-textvariable=>\$self->{lownr},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
}

#package SP;
sub fillstatus {
	my ($self,$tw,$row,$lnktxt,$cirtxt,$quetxt,$restxt) = @_;
	my $f;

	$lnktxt = 'Linksets' unless defined $lnktxt;
	$cirtxt = 'Circuits' unless defined $cirtxt;
	$quetxt = 'Queries' unless defined $quetxt;
	$restxt = 'Replies' unless defined $restxt;

	$f = $tw->Frame(%tframestyle,
	)->pack(%tframepack);
	$f->Checkbutton(%buttonleft,
		-text=>'Exchange SLTM',
		-variable=>\$self->{xchg_sltm},
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$f->Checkbutton(%buttonleft,
		-text=>'Exchange ISUP',
		-variable=>\$self->{xchg_isup},
	)->grid(-row=>$$row,-column=>1,-sticky=>'ewns');
	$f->Checkbutton(%buttonleft,
		-text=>'Originate TCAP',
		-variable=>\$self->{orig_tcap},
	)->grid(-row=>$$row,-column=>2,-sticky=>'ewns');
	$f->Checkbutton(%buttonleft,
		-text=>'Terminate TCAP',
		-variable=>\$self->{term_tcap},
	)->grid(-row=>$$row++,-column=>3,-sticky=>'ewns');
	$f = $tw->TFrame(%tframestyle,
		-label=>'State:',
	)->pack(%tframepack);
	$$row = 0;
	$f->Label(%labelright,
		-text=>'State:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$f->Optionmenu(%optionleft,
		-options=>\@spoptions,
		-variable=>\$self->{state},
		-textvariable=>\$self->{statetext},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	if (keys %{$self->{adjacent}}) {
		$f = $tw->TFrame(%tframestyle,
			-label=>'Linksets:',
		)->pack(%tframepack);
		$$row = 0;
		foreach my $pc (sort {$a <=> $b} keys %{$self->{adjacent}}) {
			$f->Label(%labelright,
				-text=>"$lnktxt:",
			)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
			my $pcode = main::pcstring($pc);
			my $pownr = main::pcowner($pc,0);
			$pcode .= " ($pownr)" if $pownr;
			$f->Entry(%entrycenter,
				-textvariable=>\$pcode,
			)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
		}
	}
	if (keys %{$self->{circuits}}) {
		$f = $tw->TFrame(%tframestyle,
			-label=>'Circuits:',
		)->pack(%tframepack);
		$$row = 0;
		$f->Label(%labelcenter,
			-text=>'Point Code',
		)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
		$f->Label(%labelcenter,
			-text=>'Alloc.',
		)->grid(-row=>$$row,-column=>1,-sticky=>'ewns');
		$f->Label(%labelcenter,
			-text=>'Act.',
		)->grid(-row=>$$row,-column=>2,-sticky=>'ewns');
		$f->Label(%labelcenter,
			-text=>'O/G',
		)->grid(-row=>$$row,-column=>3,-sticky=>'ewns');
		$f->Label(%labelcenter,
			-text=>'I/C',
		)->grid(-row=>$$row,-column=>4,-sticky=>'ewns');
		$f->Label(%labelcenter,
			-text=>'2/W',
		)->grid(-row=>$$row++,-column=>5,-sticky=>'ewns');
		foreach my $pc (sort {$a <=> $b} keys %{$self->{circuits}}) {
			my ($ogcol,$iccol);
			if ($self->{way} eq 'O')
			{ $ogcol = 3; $iccol = 4; } else
			{ $ogcol = 4; $iccol = 3; }
			my $pcode = main::pcstring($pc);
			my $pownr = main::pcowner($pc,0);
			$pcode .= " ($pownr)" if $pownr;
			$f->Entry(%entrycenter,
				-textvariable=>\$pcode,
			)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
			$f->Entry(%entryright,
				-textvariable=>\$self->{relate}->{$pc}->{ciccnt},
			)->grid(-row=>$$row,-column=>1,-sticky=>'ewns');
			$f->Entry(%entryright,
				-textvariable=>\$self->{relate}->{$pc}->{actcnt},
			)->grid(-row=>$$row,-column=>2,-sticky=>'ewns');
			$f->Entry(%entryright,
				-textvariable=>\$self->{relate}->{$pc}->{actforw},
			)->grid(-row=>$$row,-column=>$ogcol,-sticky=>'ewns');
			$f->Entry(%entryright,
				-textvariable=>\$self->{relate}->{$pc}->{actrevs},
			)->grid(-row=>$$row,-column=>$iccol,-sticky=>'ewns');
			$f->Entry(%entryright,
				-textvariable=>\$self->{relate}->{$pc}->{actboth},
			)->grid(-row=>$$row++,-column=>5,-sticky=>'ewns');
		}
	}
	if (keys %{$self->{tqueries}} || keys %{$self->{responds}}) {
		$f = $tw->TFrame(%tframestyle,
			-label=>'Queries:',
		)->pack(%tframepack);
		$$row = 0;
		my $col = 0;
		foreach my $pc (sort {$a <=> $b} keys %{$self->{tqueries}}) {
			if ($col == 0) {
				$f->Label(%labelright,
					-text=>"$quetxt:",
				)->grid(-row=>$$row,-column=>$col,-sticky=>'ewns');
			}
			$col++;
			my $pcode = main::pcstring($pc);
			my $pownr = main::pcowner($pc,0);
			$pcode .= " ($pownr)" if $pownr;
			$f->Entry(%entrycenter,
				-textvariable=>\$pcode,
			)->grid(-row=>$$row,-column=>$col,-sticky=>'ewns');
			if ($col > 5) {
				$col = 0;
				$$row++;
			}
		}
		if ($col != 0) {
			$col = 0;
			$$row++;
		}
		foreach my $pc (sort {$a <=> $b} keys %{$self->{responds}}) {
			if ($col == 0) {
				$f->Label(%labelright,
					-text=>"$restxt:",
				)->grid(-row=>$$row,-column=>$col,-sticky=>'ewns');
			}
			$col++;
			my $pcode = main::pcstring($pc);
			my $pownr = main::pcowner($pc,0);
			$pcode .= " ($pownr)" if $pownr;
			$f->Entry(%entrycenter,
				-textvariable=>\$pcode,
			)->grid(-row=>$$row,-column=>$col,-sticky=>'ewns');
			if ($col > 5) {
				$col = 0;
				$$row++;
			}
		}
	}
}

# -------------------------------------
package SSP;
use strict;
use vars qw(@ISA);
@ISA = qw(SP);
# -------------------------------------

#package SSP;
sub xform {
	my ($type,$self) = @_;
	return if $self->{type} == 1;
	return if ref $self eq $type;
	bless $self,$type;
	my $x = $self->{x};
	my $y = $self->{y};
	$main::mycanvas->delballoon($self->{item});
	$main::canvas->delete($self->{item});
	$self->{item} = $main::canvas->createOval(
		$x-33,$y-33,$x+33,$y+33,
		-fill=>'white',
		-outline=>'black',
		-width=>2,
		-tags=>['ssp','node'],
	);
	$main::canvas->raise('node','path');
	$main::canvas->coords($self->{scri},
		$x-23,$y-23,$x+23,$y+23,$x+23,$y-23,$x-23,$y+23,$x-23,$y-23,
	);
	$main::canvas->itemconfigure($self->{ttxt}, -text=>'SSP');
	if ($self->{alias}) {
		$main::canvas->itemconfigure($self->{item}, -dash=>[5,2]);
		$main::canvas->itemconfigure($self->{scri}, -dash=>[5,2]);
	}
	$self->{type} = 1;
	$main::canvas->bind($self->{item},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->bind($self->{scri},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->bind($self->{ttxt},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->bind($self->{text},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->bind($self->{ownr},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]) if $self->{ownr};
	$main::mycanvas->addballoon($self->{item}, $self->identify,
				    $self->{scri}, $self->identify,
				    $self->{ttxt}, $self->identify,
				    $self->{text}, $self->identify);
#	$main::canvas->idletasks;
	$main::top->{updatenow} = 1;
	$::statusbar->configure(-text=>"Discovered ".$self->identify);
}

#package SSP;
sub fillstatus {
	my ($self,$tw,$row) = @_;
	$self->SP::fillstatus($tw,$row,
		'Linksets to',
		'Circuits to',
		'Query to',
		'Reply from',
	);
}

# -------------------------------------
package SCP;
use strict;
use vars qw(@ISA);
@ISA = qw(SP);
# -------------------------------------

#package SCP;
sub xform {
	my ($type,$self) = @_;
	return if $self->{type} == 2;
	return if ref $self eq $type;
	bless $self,$type;
	my $x = $self->{x};
	my $y = $self->{y};
	$main::mycanvas->delballoon($self->{item});
	$main::canvas->delete($self->{item});
	$self->{item} = $main::canvas->createOval(
		$x-33,$y-23,$x+33,$y+23,
		-fill=>'white',
		-outline=>'black',
		-width=>2,
		-tags=>['scp','node'],
	);
	$main::canvas->raise('node','path');
	$main::canvas->itemconfigure($self->{ttxt}, -text=>'SCP');
	if ($self->{alias}) {
		$main::canvas->itemconfigure($self->{item}, -dash=>[5,2]);
	}
	$self->{type} = 2;
	$main::canvas->bind($self->{item},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->bind($self->{scri},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->bind($self->{ttxt},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->bind($self->{text},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->bind($self->{ownr},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]) if $self->{ownr};
	$main::mycanvas->addballoon($self->{item}, $self->identify,
				    $self->{scri}, $self->identify,
				    $self->{ttxt}, $self->identify,
				    $self->{text}, $self->identify);
#	$main::canvas->idletasks;
	$main::top->{updatenow} = 1;
	$::statusbar->configure(-text=>"Discovered ".$self->identify);
}

#package SCP;
sub fillstatus {
	my ($self,$tw,$row) = @_;
	$self->SP::fillstatus($tw,$row,
		'Linksets to',
		'Circuits to',
		'Responds to',
		'Responds to',
	);
}

# -------------------------------------
package STP;
use strict;
use vars qw(@ISA);
@ISA = qw(SP);
# -------------------------------------

#package STP;
sub xform {
	my ($type,$self) = @_;
	return if $self->{type} == 3;
	return if ref $self eq $type;
	bless $self,$type;
	my $x = $self->{x};
	my $y = $self->{y};
	$main::mycanvas->delballoon($self->{item});
	$main::canvas->delete($self->{item});
	$self->{item} = $main::canvas->createRectangle(
		$x-28,$y-28,$x+28,$y+28,
		-fill=>'white',
		-outline=>'black',
		-width=>2,
		-tags=>['stp','node'],
	);
	$main::canvas->raise('node','path');
	$main::canvas->coords($self->{scri}, $x+28,$y-28,$x-28,$y+28);
	$main::canvas->itemconfigure($self->{ttxt}, -text=>'STP');
	$self->{type} = 3;
	$main::canvas->bind($self->{item},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->bind($self->{scri},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->bind($self->{ttxt},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->bind($self->{text},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->bind($self->{ownr},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]) if $self->{ownr};
	$main::mycanvas->addballoon($self->{item}, $self->identify,
				    $self->{scri}, $self->identify,
				    $self->{ttxt}, $self->identify,
				    $self->{text}, $self->identify);
#	$main::canvas->idletasks;
	$main::top->{updatenow} = 1;
	$::statusbar->configure(-text=>"Discovered ".$self->identify);
}

#package STP;
sub fillstatus {
	my ($self,$tw,$row) = @_;
	$self->SP::fillstatus($tw,$row,
		'Linksets to',
		'Circuits to',
		'Queries',
		'Translates from',
	);
}

# -------------------------------------
package GTT;
use strict;
use vars qw(@ISA);
@ISA = qw(SP);
# -------------------------------------

#package GTT;
sub xform {
	my ($type,$self) = @_;
	return if $self->{type} == 4;
	return if ref $self eq $type;
	bless $self,$type;
	my $x = $self->{x};
	my $y = $self->{y};
	$main::mycanvas->delballoon($self->{item});
	$main::canvas->delete($self->{item});
	$self->{item} = $main::canvas->createRectangle(
		$x-28,$y-28,$x+28,$y+28,
		-dash=>[5,2],
		-fill=>'white',
		-outline=>'black',
		-width=>2,
		-tags=>['stp','node'],
	);
	$main::canvas->raise('node','path');
	$main::canvas->coords($self->{scri}, $x+28,$y-28,$x-28,$y+28);
	$main::canvas->itemconfigure($self->{scri}, -dash=>[5,2]);
	$main::canvas->itemconfigure($self->{ttxt}, -text=>'GTT');
	$self->{type} = 4;
	$main::canvas->bind($self->{item},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->bind($self->{scri},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->bind($self->{ttxt},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->bind($self->{text},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->bind($self->{ownr},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]) if $self->{ownr};
	$main::mycanvas->addballoon($self->{item}, $self->identify,
				    $self->{scri}, $self->identify,
				    $self->{ttxt}, $self->identify,
				    $self->{text}, $self->identify);
#	$main::canvas->idletasks;
	$main::top->{updatenow} = 1;
	$::statusbar->configure(-text=>"Discovered ".$self->identify);
}

#package GTT;
sub fillstatus {
	my ($self,$tw,$row) = @_;
	$self->SP::fillstatus($tw,$row,
		'Linksets to',
		'Circuits to',
		'Queries',
		'Translates from',
	);
}

# -------------------------------------
package Network;
use strict;
use vars qw(@ISA);
@ISA = qw(MsgStats Logging Properties Status Clickable);
# -------------------------------------

my $network;

#package Network;
sub new {
	my ($type,@args) = @_;
	my $self = {};
	bless $self,$type;
	$self->MsgStats::init(@args);
	$self->Logging::init(@args);
	$self->Properties::init(@args);
	$self->Status::init(@args);
	$self->{ciccnt} = 0;
	$self->{actcnt} = 0;
	$self->{act1w} = 0;
	$self->{act2w} = 0;
	$self->{nodes} = {};
	$self->{nodeno} = 0;
	$self->{paths} = {};
	$self->{pathno} = 0;
	$self->{relations} = {};
	$self->{relationno} = 0;
	$main::canvas->CanvasBind('<ButtonPress-3>',[\&Network::button3,$self,Tk::Ev('X'),Tk::Ev('Y'),Tk::Ev('x'),Tk::Ev('y')]);
	$Network::network = $self;
	$::statusbar->configure(-text=>"New ".$self->identify);
	return $self;
}

#package Network;
sub identify {
	my $self = shift;
	return "Newtork";
}

#package Network;
sub shortid {
	my $self = shift;
	return "NET";
}

#package Network;
sub getPath {
	my ($self,$ppa,@args) = @_;
	return $self->{paths}->{$ppa} if exists $self->{paths}->{$ppa};
	my $pathno = $self->{pathno} + 1;
	my $path = Path->new($self,$pathno,$ppa,@args);
	$self->{paths}->{$ppa} = $path;
	$self->{pathno} = $pathno;
	return $path;
}

#package Network;
sub getSp {
	my ($self,$pc,@args) = @_;
	return $self->{nodes}->{$pc} if exists $self->{nodes}->{$pc};
	my $nodeno = $self->{nodeno} + 1;
	my $node = SP->new($self,$nodeno,$pc,@args);
	$self->{nodes}->{$pc} = $node;
	$self->{nodeno} = $nodeno;
	return $node;
}

#package Network;
sub getRelation {
	my ($self,$nodea,$nodeb,@args) = @_;
	my $key = "$nodea->{pc},$nodeb->{pc}";
	return $self->{relations}->{$key} if exists $self->{relations}->{$key};
	my $relationno = $self->{relationno} + 1;
	my $relation = Relation->new($self,$relationno,$nodea,$nodeb,@args);
	$self->{relations}->{$key} = $relation;
	$key = "$nodeb->{pc},$nodea->{pc}";
	$self->{relations}->{$key} = $relation;
	$self->{relationno} = $relationno;
	return $relation;
}

#package Network;
sub getLinkSet {
	my ($self,@args) = @_;
	my $linkset = $self->getRelation(@args); 
	if (ref $linkset eq 'Relation') {
		Linkset->xform($linkset);
	}
	return $linkset;
}

#package Network;
sub regroupsps {
	my $self = shift;
	my %totals;
	while (my ($pc,$node) = each %{$self->{nodes}}) {
		my $col = $node->{col};
		$totals{$col} += 1;
	}
	my %counts;
	foreach my $pc (sort {$a <=> $b} keys %{$self->{nodes}}) {
		my $node = $self->{nodes}->{$pc};
		my $col = $node->{col};
		my $row = $counts{$col} - $totals{$col};
		$counts{$col} += 2;
		$node->movesp($col,$row);
	}
}

#package Network;
sub button3 {
	my ($canvas,$self,$X,$Y,$x,$y) = @_;
	my $cx = $canvas->canvasx($x,1);
	my $cy = $canvas->canvasy($y,1);
	if ($canvas->find('overlapping', $cx - 2, $cy - 2, $cx + 2, $cy + 2)) {
		return;
	}
	return shift->Clickable::button3(@_);
}

#package Network;
sub fillprops {
	my ($self,$tw,$row) = @_;
}

#package Network;
sub fillstatus {
	my ($self,$tw,$row) = @_;

	$tw->Label(%labelright,
		-text=>'Number of paths:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Entry(%entryright,
		-textvariable=>\$self->{pathno},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'Number of nodes:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Entry(%entryright,
		-textvariable=>\$self->{nodeno},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'Number of signalling relations:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Entry(%entryright,
		-textvariable=>\$self->{relationno},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'Number of circuits:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Entry(%entryright,
		-textvariable=>\$self->{ciccnt},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'Number of active circuits:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Entry(%entryright,
		-textvariable=>\$self->{actcnt},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'Number of active one-way circuits:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Entry(%entryright,
		-textvariable=>\$self->{act1w},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'Number of active both-way circuits:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Entry(%entryright,
		-textvariable=>\$self->{act2w},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
}

# -------------------------------------
package Path;
use strict;
use vars qw(@ISA);
@ISA = qw(MsgStats Logging Properties Status Clickable);
# -------------------------------------

use constant {
	RT_UNKNOWN => 0,
	RT_14BIT_PC => 4, # also RL length in octets
	RT_24BIT_PC => 7  # also RL length in octets
};
my @rloptions = (
	['Unknown'	     => RT_UNKNOWN ],
	['14-bit point code' => RT_14BIT_PC],
	['24-bit point code' => RT_24BIT_PC],
);
use constant {
	HT_UNKNOWN => 0,
	HT_BASIC => 3,	 # also link level header length
	HT_EXTENDED => 6 # also link level header length
};
my @htoptions = (
	['Unknown'  => HT_UNKNOWN ],
	['Basic'    => HT_BASIC	  ],
	['Extended' => HT_EXTENDED],
);
use constant {
	MP_UNKNOWN => 0,
	MP_JAPAN => 1,
	MP_NATIONAL => 2,
	MP_INTERNATIONAL => 3
};
my @mpoptions = (
	['Unknown'	    => MP_UNKNOWN	],
	['Japan'	    => MP_JAPAN		],
	['National'	    => MP_NATIONAL	],
	['International'    => MP_INTERNATIONAL	],
);

my %paths;
my $pathno = 0;

#package Path;
sub init {
	my ($self,$pathno,$ppa,@args) = @_;
	$self->MsgStats::init(@args);
	$self->Logging::init(@args);
	$self->Properties::init(@args);
	$self->Status::init(@args);
	$self->{ppa} = $ppa;
	$self->{slot} = (($ppa >> 0) & 0x1f);
	$self->{span} = (($ppa >> 5) & 0x03);
	$self->{card} = (($ppa >> 7) & 0x01);
	$self->{msgs} = ();
	$self->{ht} = HT_UNKNOWN;
	$self->{httext} = 'Unknown';
	$self->{pr} = MP_UNKNOWN;
	$self->{prtext} = 'Unknown';
	$self->{rt} = RT_UNKNOWN;
	$self->{rttext} = 'Unknown';
	$self->{orig} = {};
	$self->{dest} = {};
	$self->{opcs} = {};
	$self->{dpcs} = {};
	$self->{routes} = {};
	#print "Created new path ($self->{card}:$self->{span}:$self->{slot}).\n";
	$self->{fill} = 'red';
	my $cola = $self->{cola} = 0 - SP::COL_ADJ;
	my $rowa = $self->{rowa} = $pathno * 2;
	my $colb = $self->{colb} = 0 + SP::COL_ADJ;
	my $rowb = $self->{rowb} = $pathno * 2;
	my $xa = $self->{xa} = $main::mycanvas->colpos($cola);
	my $ya = $self->{ya} = $main::mycanvas->rowpos($rowa);
	my $xb = $self->{xb} = $main::mycanvas->colpos($colb);
	my $yb = $self->{yb} = $main::mycanvas->rowpos($rowb);
	$self->{x} = ($xa + $xb)/2;
	$self->{y} = ($ya + $yb)/2;
	$self->{item} = $main::canvas->createLine($xa,$ya,$xb,$yb,
		-arrow=>'last',
		-capstyle=>'round',
		-fill=>$self->{fill},
		-joinstyle=>'round',
		-smooth=>0,
		-tags=>['path'],
		-width=>4,
	);
	$main::canvas->bind($self->{item},'<ButtonPress-3>',[\&Clickable::button3,$self,Tk::Ev('X'),Tk::Ev('Y')]);
	$main::canvas->lower('path','node');
	$main::mycanvas->addballoon($self->{item}, $self->identify);
#	$main::canvas->idletasks;
	$main::top->{updatenow} = 1;
}

#package Path;
sub new {
	my ($type,$network,@args) = @_;
	my $self = {};
	bless $self,$type;
	$self->{network} = $network;
	$self->init(@args);
	$::statusbar->configure(-text=>"New ".$self->identify);
	return $self;
}

#package Path;
sub get {
	my ($type,$ppa,@args) = @_;
	return $paths{$ppa} if exists $paths{$ppa};
	my $self = {};
	bless $self, $type;
	$paths{$ppa} = $self;
	$pathno = $pathno + 1;
	$self->init($pathno,$ppa,@args);
	return $self;
}

#package Path;
sub findalias {
	my ($self,$node,@routes) = @_;
	return unless ref $node eq 'SSP' or ref $node eq 'SCP';
	my $col = Linkset::COL_GTT;
	foreach my $route (@routes) {
		my $alias = $route->{node};
		next unless $alias->{'pc'} != $node->{'pc'};
		if (abs($alias->{col}) != $col) {
			my $newcol = $col;
			if ($alias->{col} < 0) { $newcol = -$col; }
			$alias->movesp($newcol,$alias->{row});
			$alias->{alias} = 1;
			$main::canvas->itemconfigure($alias->{item}, -dash=>[5,2]);
			$main::canvas->itemconfigure($alias->{scri}, -dash=>[5,2]);
			$::statusbar->configure(-text=>"Discovered alias ".$alias->identify);
		}
	}
}

#package Path;
sub bindpath {
	my ($self,$network,$nodea,$nodeb,$slc) = @_;
	$self->{slc} = $slc;
	$self->{nodea} = $nodea;
	$self->{nodeb} = $nodeb;
	$self->{slc} = $slc;
	my $linkset = $network->getLinkSet($nodea,$nodeb);
	my $link = $linkset->getLink($nodea,$nodeb,$slc);
	$self->{link} = $link;
	$link->addPath($self);
	$self->findalias($nodea,(values %{$self->{opcs}}));
	$self->findalias($nodeb,(values %{$self->{dpcs}}));
	$main::canvas->itemconfigure($self->{item}, -state=>'hidden');
	$self->move;
	$network->regroupsps;
#	$main::canvas->idletasks;
	$main::top->{updatenow} = 1;
}

#package Path;
sub cardnum {
	shift->{card};
}
#package Path;
sub spannum {
	shift->{span};
}
#package Path;
sub slotnum {
	shift->{slot};
}
#package Path;
sub ppa {
	shift->{ppa};
}
#package Path;
sub add {
	my ($self,$msg,@args) = @_;
	unless ($self->{detected}) {
		if ($self->detecting) {
			push @{$self->{msgs}}, $msg;
			return;
		}
		$self->{detected} = 1;
		push @{$self->{msgs}}, $msg;
		while ($msg = pop @{$self->{msgs}}) {
			$self->complete($msg);
		}
	} else {
		$self->complete($msg);
	}
}
#package Path;
sub complete {
	my ($self,$msg,@args) = @_;
	$self->inc($msg,'0');
	my ($nodeb,$nodea,$pc,$route);
	my $network = $self->{network};
	if (exists $msg->{opc}) {
		$pc = $msg->{opc};
		if ($route = $self->{opcs}->{$pc}) {
			$nodea = $route->{node};
			$self->swap if $nodea->{col} < 0 && $self->{cola} > 0;
		} else {
			$nodea = $network->getSp($pc, $self, $self->{cola},'O');
			$self->swap if $nodea->{col} < 0 && $self->{cola} > 0;
			$route = Route->new($self,'a',$nodea);
			$self->{opcs}->{$pc} = $route;
			$self->findalias($self->{nodea},(values %{$self->{opcs}})) if $self->{nodea};
			$self->findalias($self->{nodeb},(values %{$self->{dpcs}})) if $self->{nodeb};
			$network->regroupsps;
		}
		$route->inc($msg,'0');
		$nodea->add_orig($msg);
	}
	if (exists $msg->{dpc}) {
		$pc = $msg->{dpc};
		if ($route = $self->{dpcs}->{$pc}) {
			$nodeb = $route->{node};
			$self->swap if $nodeb->{col} < 0 && $self->{colb} > 0;
		} else {
			$nodeb = $network->getSp($pc, $self, $self->{colb},'I');
			$self->swap if $nodeb->{col} < 0 && $self->{colb} > 0;
			$route = Route->new($self,'b',$nodeb);
			$self->{dpcs}->{$pc} = $route;
			$self->findalias($self->{nodea},(values %{$self->{opcs}})) if $self->{nodea};
			$self->findalias($self->{nodeb},(values %{$self->{dpcs}})) if $self->{nodeb};
			$network->regroupsps;
		}
		$route->inc($msg,'1');
		$nodeb->add_term($msg);
	}
	if (exists $msg->{dpc} && exists $msg->{opc}) {
		my $rela = $network->getRelation($nodea,$nodeb);
		$rela->add($msg);
		if ($msg->{si} == 1 || $msg->{si} == 2) {
			if ($msg->{mt} == 0x11 || $msg->{mt} == 0x12) {
				$self->bindpath($network,$nodea,$nodeb,$msg->{slc});
			}
		}
	}
}
#package Path;
sub swap {
	my $self = shift;
	$self->movepath(-$self->{cola},$self->{rowa}, -$self->{colb},$self->{rowb});
	while (my ($k,$node) = each %{$self->{opcs}}) {
		$node->swap if $self->{cola} < 0 && $node->{col} > 0;
	}
	while (my ($k,$node) = each %{$self->{dpcs}}) {
		$node->swap if $self->{colb} < 0 && $node->{col} > 0;
	}
}
#package Path;
sub detecting {
	my $self = shift;
	return 0 if ($self->{ht} != 0 && $self->{pr} != 0 && $self->{rt} != 0);
	return 1;
}

#package Path;
sub setht {
	my ($self,$ht) = @_;
	$self->{ht} = $ht;
	if ($ht == HT_UNKNOWN) {
		$self->{httext} = 'Unknown';
	} elsif ($ht == HT_BASIC) {
		$self->{httext} = 'Basic';
	} elsif ($ht == HT_EXTENDED) {
		$self->{httext} = 'Extended';
	}
}
#package Path;
sub setrt {
	my ($self,$rt) = @_;
	$self->{rt} = $rt;
	if ($rt == RT_UNKNOWN) {
		$self->{rttext} = 'Unknown';
	} elsif ($rt == RT_14BIT_PC) {
		$self->{rttext} = '14-bit point code';
	} elsif ($rt == RT_24BIT_PC) {
		$self->{rttext} = '24-bit point code';
	}
}
#package Path;
sub setpr {
	my ($self,$pr) = @_;
	$self->{pr} = $pr;
	if ($pr == MP_UNKNOWN) {
		$self->{prtext} = 'Unknown';
	} elsif ($pr == MP_JAPAN) {
		$self->{prtext} = 'Japan';
	} elsif ($pr == MP_NATIONAL) {
		$self->{prtext} = 'National';
	} elsif ($pr == MP_INTERNATIONAL) {
		$self->{prtext} = 'International';
	}
}

#package Path;
sub move {
	my $self = shift;
	my $nodea = $self->{nodea};
	my $nodeb = $self->{nodeb};
	my $xa = $nodea->{x};
	my $ya = $nodea->{y};
	my $xb = $nodeb->{x};
	my $yb = $nodeb->{y};
	return if $xa == $self->{xa} &&
		  $ya == $self->{ya} &&
		  $xb == $self->{xb} &&
		  $yb == $self->{yb};
	$self->{cola} = $nodea->{col};
	$self->{rowa} = $nodea->{row};
	$self->{colb} = $nodeb->{col};
	$self->{rowb} = $nodeb->{row};
	$main::canvas->coords($self->{item},$xa,$ya,$xb,$yb);
	$self->{xa} = $xa;
	$self->{ya} = $ya;
	$self->{xb} = $xb;
	$self->{yb} = $yb;
	$self->{x} = ($xa + $xb)/2;
	$self->{y} = ($ya + $yb)/2;
	while (my ($k,$r) = each %{$self->{routes}}) { $r->move; }
}

#package Path;
sub movepath {
	my ($self,$cola,$rowa,$colb,$rowb) = @_;
	return if $cola == $self->{cola} &&
	          $rowa == $self->{rowa} &&
		  $colb == $self->{colb} &&
		  $rowb == $self->{rowb};
	my $xa = $self->{xa} = $main::mycanvas->colpos($cola);
	my $ya = $self->{ya} = $main::mycanvas->rowpos($rowa);
	my $xb = $self->{xb} = $main::mycanvas->colpos($colb);
	my $yb = $self->{yb} = $main::mycanvas->rowpos($rowb);
	$self->{x} = ($xa + $xb)/2;
	$self->{y} = ($ya + $yb)/2;
	$self->{cola} = $cola;
	$self->{rowa} = $rowa;
	$self->{colb} = $colb;
	$self->{rowb} = $rowb;
	$main::canvas->coords($self->{item},$xa,$ya,$xb,$yb);
	$main::canvas->lower('path','node');
	while (my ($k,$v) = each %{$self->{routes}}) {
		$v->move($self);
	}
}

#package Path;
sub identify {
	my $self = shift;
	my $id = "Path $self->{card}:$self->{span}:$self->{slot},";
	$id .= " $self->{nodea}->{pcode} -> $self->{nodeb}->{pcode} link $self->{slc}" if $self->{nodea};
	return $id;
}

#package Path;
sub shortid {
	my $self = shift;
	return "$self->{card}:$self->{span}:$self->{slot}";
}

#package Path;
sub fillprops {
	my ($self,$tw,$row) = @_;

	my $ppa = "$self->{card}:$self->{span}:$self->{slot}";
	$tw->Label(%labelright,
		-text=>'Channel:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Entry(%entryleft,
		-textvariable=>\$ppa,
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
}

#package Path;
sub fillstatus {
	my ($self,$tw,$row) = @_;

	my $ppa = "$self->{card}:$self->{span}:$self->{slot}";
	if ($self->{nodea} && $self->{nodeb}) {
		$tw->Label(%labelright,
			-text=>'Signalling link code:',
		)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
		$tw->Entry(%entryleft,
			-textvariable=>\$self->{slc},
		)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	}
	if ($self->{nodea}) {
		$tw->Label(%labelright,
			-text=>'SP A point code:',
		)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
		$tw->Entry(%entryleft,
			-textvariable=>\$self->{nodea}->{pcode},
		)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	}
	if ($self->{nodeb}) {
		$tw->Label(%labelright,
			-text=>'SP B point code:',
		)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
		$tw->Entry(%entryleft,
			-textvariable=>\$self->{nodeb}->{pcode},
		)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	}
	$tw->Label(%labelright,
		-text=>'Header type:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Optionmenu(%optionleft,
		-options=>\@htoptions,
		-variable=>\$self->{ht},
		-textvariable=>\$self->{httext},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'Message priority:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Optionmenu(%optionleft,
		-options=>\@mpoptions,
		-variable=>\$self->{pr},
		-textvariable=>\$self->{prtext},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
	$tw->Label(%labelright,
		-text=>'Routing label type:',
	)->grid(-row=>$$row,-column=>0,-sticky=>'ewns');
	$tw->Optionmenu(%optionleft,
		-options=>\@rloptions,
		-variable=>\$self->{rt},
		-textvariable=>\$self->{rttext},
	)->grid(-row=>$$row++,-column=>1,-sticky=>'ewns');
}

# -------------------------------------
package Message;
use strict;
# -------------------------------------

use constant {
	RT_UNKNOWN => 0,
	RT_14BIT_PC => 4, # also RL length in octets
	RT_24BIT_PC => 7  # also RL length in octets
};
use constant {
	HT_UNKNOWN => 0,
	HT_BASIC => 3,	 # also link level header length
	HT_EXTENDED => 6 # also link level header length
};
use constant {
	MP_UNKNOWN => 0,
	MP_JAPAN => 1,
	MP_NATIONAL => 2,
	MP_INTERNATIONAL => 3
};

my $count = 0;

# $msg = Message::create($pcap);
#package Message;
sub create {
	my $type = shift;
	my $self = {};
	bless $self, $type;
	my $pcap = shift;
	my %hdr;
	my $dat = '';
	$self->{hdr} = {};
	$self->{dat} = '';
	my $ret = Net::Pcap::pcap_next_ex($pcap, \%hdr, \$dat);
	$self->{hdr}->{len} = $hdr{len} - 4;
	$self->{hdr}->{caplen} = $hdr{caplen} - 4;
	$self->{hdr}->{tv_sec} = $hdr{tv_sec};
	$self->{hdr}->{tv_usec} = $hdr{tv_usec};
	$self->{dat} = substr($dat, 4);
	return undef if $ret != 1;
	$main::count += 1;
	my ( $dir, $xsn, $lkno0, $lkno1 ) = unpack('CCCC', $dat);
	$self->{dir} = $dir;
	$self->{xsn} = $xsn;
	$self->{ppa} = ($lkno0 << 8) | $lkno1;
	return $self;
}

#package Message;
sub process {
	my ($self,$network) = @_;
	my $path = $network->getPath($self->{ppa});
	if ($self->decode($path) >= 0) {
		$path->add($self);
		return;
	}
	#print STDERR "decoding error\n";
}

#package Message;
sub getCount {
	return $main::count;
}

#package Message;
sub decode {
	my ($self,$path,@args) = @_;
	my @b = (unpack('C*', substr($self->{dat}, 0, 8)));
	if (!exists $self->{mtp2decode}) {
		my $len = $self->{hdr}->{len};
		if (3 <= $len && $len <= 5) {
			$path->setht(HT_BASIC);
		} elsif (6 <= $len && $len <= 8) {
			$path->setht(HT_EXTENDED);
		}
		return 0 unless $path->{ht} != HT_UNKNOWN;
		my ($bsn,$bib,$fsn,$fib,$li,$li0);
		if ($path->{ht} == HT_BASIC) {
			$self->{bsn} = $b[0] & 0x7f;
			$self->{bib} = $b[0] >> 7;
			$self->{fsn} = $b[1] & 0x7f;
			$self->{fib} = $b[1] >> 7;
			$self->{li} = $b[2] & 0x3f;
			$self->{li0} = $b[2] >> 6;
		} elsif ($path->{ht} == HT_EXTENDED) {
			$self->{bsn} = $b[0];
			$self->{bsn} |= ($b[1] & 0x0f) << 8;
			$self->{bib} = $b[1] >> 7;
			$self->{fsn} = $b[2];
			$self->{fsn} |= ($b[3] & 0x0f) << 8;
			$self->{fib} = $b[3] >> 7;
			$self->{li} = $b[4];
			$self->{li} |= ($b[5] & 0x1) << 8;
			$self->{li0} = $b[5] >> 6;
		}
		my $inf = $len - $path->{ht};
		if (($self->{li} != $inf) && ($inf <= 63 || $self->{li} != 63)) {
			print STDERR "bad length indicator $self->{li} != $inf\n";
		}
		if ($self->{li0} != 0) {
			$path->setrt(RT_24BIT_PC);
			$path->setpr(MP_JAPAN);
		}
		$self->{mtp2decode} = 1;
	}
	return 1 if $self->{li} == 0;
	@b = (unpack('C*', substr($self->{dat}, $path->{ht}, 11)));
	$self->{si} = $b[0];
	return 1 if $self->{li} < 3;
	$self->{ni} = ($b[0] & 0xc0) >> 6;
	$self->{mp} = ($b[0] & 0x30) >> 4;
	$self->{si} = ($b[0] & 0x0f);
	if ($self->{ni} == 0) {
		$path->setrt(RT_14BIT_PC);
		$path->setpr(MP_INTERNATIONAL);
	}
	if ($path->{pr} == MP_UNKNOWN) {
		$path->setpr(MP_NATIONAL) if $self->{mp} != 0;
	} elsif ($path->{pr} == MP_JAPAN) {
		$self->{mp} = $self->{li0};
	} elsif ($path->{pr} == MP_INTERNATIONAL) {
		$self->{mp} = 0;
	}
	if ($self->{li} < HT_EXTENDED) {
		print STDERR "too short for RL, li = $self->{li}\n";
		return -1;
	}
	if ($self->{li} < 9 || ($self->{si} == 5 && $self->{li} < 11)) {
		$path->setrt(RT_14BIT_PC);
	}
	if ($path->{rt} == RT_UNKNOWN) {
		my $ret = $self->checkRoutingLabelType($self->{si},$path,$self->{li},\@b) < 0;
		return $ret if $ret <= 0;
		print "check succeeded on si=$self->{si}, mt=$self->{mt}";
	}
	if (!exists $self->{mtp3decode}) {
		return 0 if $path->detecting;
		if ($path->{rt} == RT_14BIT_PC) {
			if ($self->{li} < 6) {
				print STDERR "too short for 14-bit RL, li = $self->{li}\n";
				return -1;
			}
			$self->{dpc} = $b[1];
			$self->{dpc} |= ($b[2] & 0x3f) << 8;
			$self->{opc} = ($b[2] & 0xc0) >> 6;
			$self->{opc} |= $b[3] << 2;
			$self->{opc} |= ($b[4] & 0x0f) << 10;
			$self->{sls} = $b[4] >> 4;
		} else {
			if ($self->{li} < 9) {
				print STDERR "too short for 24-bit RL, li = $self->{li}\n";
				return -1;
			}
			$self->{dpc} = $b[1];
			$self->{dpc} |= $b[2] << 8;
			$self->{dpc} |= $b[3] << 16;
			$self->{opc} = $b[4];
			$self->{opc} |= $b[5] << 8;
			$self->{opc} |= $b[6] << 16;
			$self->{sls} = $b[7];
		}
		@b = (unpack('C*', substr($self->{dat}, $path->{ht} + 1 + $path->{rt}, 3)));
		if ($self->{si} == 5) {
			$self->{cic} = $b[0];
			$self->{cic} |= $b[1] << 8;
			$self->{mt} = $b[2];
		} elsif ($self->{si} < 3) {
			$self->{mt} = (($b[0] & 0x0f) << 4) | ($b[0] >> 4);
		} else {
			$self->{mt} = $b[0];
		}
		unless (exists $mtypes{$self->{si}}) {
			print STDERR "no message type for si=$self->{si}\n";
			return -1;
		}
		unless (exists $mtypes{$self->{si}}->{$self->{mt}}) {
			print STDERR "no message type for si=$self->{si}, mt=$self->{mt}\n";
			return -1;
		}
		if ($self->{si} == 1 || $self->{si} == 2) {
			if ($path->{rt} == RT_14BIT_PC) {
				$self->{slc} = $self->{sls};
			} else {
				$self->{slc} = $b[1] & 0x0f;
			}
			$self->{dlen} = $b[1] >> 4;
		}
		$self->{mtp3decode} = 1;
	}
	return 1;
}

#package Message;
sub checkRoutingLabelType {
	my ($self,$si,@args) = @_;
	if ($si == 0) {
		return $self->checkSnmm(@args);
	} elsif ($si == 1) {
		return $self->checkSntm(@args);
	} elsif ($si == 2) {
		return $self->checkSnsm(@args);
	} elsif ($si == 3) {
		return $self->checkSccp(@args);
	} elsif ($si == 5) {
		return $self->checkIsup(@args);
	}
	return 0;
}

use constant {
	PT_YES => 1,
	PT_MAYBE => 0,
	PT_NO => -1
};

#package Message;
sub checkSnmm {
	my ($self,$path,@args) = @_;
	my $ansi = $self->checkAnsiSnmm($path,@args);
	my $itut = $self->checkItutSnmm($path,@args);
	if ($ansi == PT_YES) {
		return 0 if $itut == PT_YES;
		$path->setrt(RT_24BIT_PC);
		return 1;
	}
	elsif ($ansi == PT_MAYBE) {
		return 0 if $itut == PT_MAYBE;
		if ($itut == PT_YES) {
			$path->setrt(RT_14BIT_PC);
		} else {
			$path->setrt(RT_24BIT_PC);
		}
		return 1;
	}
	else {
		return -1 if $itut == PT_NO;
		$path->setrt(RT_14BIT_PC);
		return 1;
	}
}
#package Message;
sub checkItutSnmm {
	my ($self,$path,$li,$b) = @_;
	my $mt = (($b->[5] & 0x0f) << 4) | ($b->[5] >> 4);

	if ($li == 6) {
		return PT_YES if $mt == 0x17 || $mt == 0x27 || $mt == 0x13 || $mt == 0x28
			|| $mt == 0x38 || $mt == 0x48 || $mt == 0x12 || $mt == 0x22 || $mt == 0x16
			|| $mt == 0x26 || $mt == 0x36 || $mt == 0x46 || $mt == 0x56 || $mt == 0x66
			|| $mt == 0x76 || $mt == 0x86;
		return PT_NO;
	}
	if ($li == 7) {
		return PT_YES if $mt == 0x11 || $mt == 0x21 || $mt == 0x51 || $mt == 0x61;
		return PT_NO;
	}
	if ($li == 8) {
		return PT_YES if $mt == 0x23 || $mt == 0x14 || $mt == 0x24 || $mt == 0x34
			|| $mt == 0x44 || $mt == 0x54 || $mt == 0x64 || $mt == 0x15 || $mt == 0x25
			|| $mt == 0x35 || $mt == 0x45;
		return PT_NO;
	}
	if ($li == 9) {
		return PT_YES if $mt == 0x1a || $mt == 0x2a || $mt == 0x3a;
		return PT_NO;
	}
	return PT_NO;
}
#package Message;
sub checkAnsiSnmm {
	my ($self,$path,$li,$b) = @_;
	my $mt = (($b->[8] & 0x0f) << 4) | ($b->[8] >> 4);

	return PT_NO if $li < 9;

	if ($li == 9) {
		return PT_YES if $mt == 0x17 || $mt == 0x27 || $mt == 0x13;
		return PT_NO;
	}
	if ($li == 10) {
		return PT_YES if $mt == 0x28 || $mt == 0x38 || $mt == 0x38 || $mt == 0x48
			|| $mt == 0x12 || $mt == 0x22 || $mt == 0x16 || $mt == 0x26 || $mt == 0x36
			|| $mt == 0x46 || $mt == 0x56 || $mt == 0x66 || $mt == 0x76 || $mt == 0x86;
		return PT_NO;
	}
	if ($li == 11) {
		return PT_YES if $mt == 0x11 || $mt == 0x21 || $mt == 0x51 || $mt == 0x61;
		return PT_NO;
	}
	if ($li == 12) {
		return PT_YES if $mt == 0x14 || $mt == 0x24 || $mt == 0x34 || $mt == 0x44
			|| $mt == 0x54 || $mt == 0x64 || $mt == 0x15 || $mt == 0x25 || $mt == 0x35
			|| $mt == 0x45 || $mt == 0x18;
		return PT_NO;
	}
	if ($li == 13) {
		return PT_YES if $mt == 0x23 || $mt == 0x1a || $mt == 0x2a || $mt == 0x3a;
		return PT_NO;
	}
	return PT_NO;
}

#package Message;
sub checkSntm {
	my ($self,$path,@args) = @_;
	my $ansi = $self->checkAnsiSntm($path,@args);
	my $itut = $self->checkItutSntm($path,@args);
	if ($ansi == PT_YES) {
		return 0 if $itut == PT_YES;
		$path->setrt(RT_24BIT_PC);
		return 1;
	}
	elsif ($ansi == PT_MAYBE) {
		return 0 if $itut == PT_MAYBE;
		if ($itut == PT_YES) {
			$path->setrt(RT_14BIT_PC);
		} else {
			$path->setrt(RT_24BIT_PC);
		}
		return 1;
	}
	else {
		return -1 if $itut == PT_NO;
		$path->setrt(RT_14BIT_PC);
		return 1;
	}
}
#package Message;
sub checkItutSntm {
	my ($self,$path,$li,$b) = @_;
	my $mt = (($b->[5] & 0x0f) << 4) | ($b->[5] >> 4);

	return PT_NO if 7 > $li || $li > 22;
	return PT_NO if $mt != 0x11 && $mt != 0x12;

	if (($b->[6] >> 4) == $li - 7) {
		return PT_YES if 7 <= $li && $li <= 9;
		return PT_MAYBE;
	}
	return PT_NO;
}
#package Message;
sub checkAnsiSntm {
	my ($self,$path,$li,$b) = @_;
	my $mt = (($b->[8] & 0x0f) << 4) | ($b->[8] >> 4);

	return PT_NO if 10 > $li || $li > 25;
	return PT_NO if $mt != 0x11 && $mt != 0x12;

	if (($b->[9] >> 4) == $li - 10) {
		return PT_YES if 23 <= $li && $li <= 25;
		return PT_MAYBE;
	}
	return PT_NO;
}
#package Message;
sub checkSnsm {
	my ($self,$path,@args) = @_;
	my $ansi = $self->checkAnsiSnsm($path,@args);
	my $itut = $self->checkItutSntm($path,@args);
	if ($ansi == PT_YES) {
		return 0 if $itut == PT_YES;
		$path->setrt(RT_24BIT_PC);
		return 1;
	}
	elsif ($ansi == PT_MAYBE) {
		return 0 if $itut == PT_MAYBE;
		if ($itut == PT_YES) {
			$path->setrt(RT_14BIT_PC);
		} else {
			$path->setrt(RT_24BIT_PC);
		}
		return 1;
	}
	else {
		return -1 if $itut == PT_NO;
		$path->setrt(RT_14BIT_PC);
		return 1;
	}
}
#package Message;
sub checkItutSnsm {
	return PT_NO;
}
#package Message;
sub checkAnsiSnsm {
	my ($self,@args) = @_;
	return $self->checkAnsiSntm(@args);
}

#package Message;
sub checkSccp {
	my ($self,$path,$li,$b) = @_;
	my $ansi = $self->checkAnsiSccp($path,$b);
	my $itut = $self->checkItutSccp($path,$b);
	if ($ansi == PT_YES) {
		return 0 if $itut == PT_YES;
		$path->setrt(RT_24BIT_PC);
		return 1;
	}
	elsif ($ansi == PT_MAYBE) {
		return 0 if $itut == PT_MAYBE;
		if ($itut == PT_YES) {
			$path->setrt(RT_14BIT_PC);
		} else {
			$path->setrt(RT_24BIT_PC);
		}
		return 1;
	}
	else {
		return -1 if $itut == PT_NO;
		$path->setrt(RT_14BIT_PC);
		return 1;
	}
}
#package Message;
sub checkItutSccp {
	my ($self,$path,$li,$b) = @_;
	my $mt = $b->[5];
	return PT_MAYBE if 0x01 <= $mt && $mt <= 0x14;
	return PT_NO;
}
#package Message;
sub checkAnsiSccp {
	my ($self,$path,$li,$b) = @_;
	my $mt = $b->[8];
	return PT_MAYBE if 0x01 <= $mt && $mt <= 0x14;
	return PT_NO;
}

#package Message;
sub checkIsup {
	my ($self,$path,@args) = @_;
	my $ansi = $self->checkAnsiIsup($path,@args);
	my $itut = $self->checkItutIsup($path,@args);
	if ($ansi == PT_YES) {
		return 0 if $itut == PT_YES;
		$path->setrt(RT_24BIT_PC);
		return 1;
	}
	elsif ($ansi == PT_MAYBE) {
		return 0 if $itut == PT_MAYBE;
		if ($itut == PT_YES) {
			$path->setrt(RT_14BIT_PC);
		} else {
			$path->setrt(RT_24BIT_PC);
		}
		return 1;
	}
	else {
		return -1 if $itut == PT_NO;
		$path->setrt(RT_14BIT_PC);
		return 1;
	}
}
#package Message;
sub checkItutIsup {
	my ($self,$path,$li,$b) = @_;
	my $mt = $b->[7];

	return PT_NO if $li < 8;

	if ($mt == 0x11 || $mt == 0x12 || $mt == 0x13 || $mt == 0x14 || $mt == 0x15 || $mt == 0x16 || $mt == 0x24 || $mt == 0x2e || $mt == 0x30 || $mt == 0x31) {
		return PT_NO if $li != 8;
		return PT_YES;
	}
	if ($mt == 0x05) {
		return PT_NO if $li != 9;
		return PT_YES;
	}
	if ($mt == 0x10 || $mt == 0x27 || $mt == 0x08 || $mt == 0x09 || $mt == 0x34 || $mt == 0x33 || $mt == 0x35 || $mt == 0x36 || $mt == 0x37 || $mt == 0x38 || $mt == 0x32) {
		return PT_NO if $li < 9;
		if ($li > 9) {
			return PT_NO if $b->[8] == 0;
			return PT_YES if $li < 11;
			return PT_MAYBE;
		}
		return PT_NO if $b->[8] != 0;
		return PT_YES;
	}
	if ($mt == 0x03 || $mt == 0x04 || $mt == 0x06 || $mt == 0x0d || $mt == 0x0e || $mt == 0x1c || $mt == 0x1d || $mt == 0x1e || $mt == 0x1f || $mt == 0x20 || $mt == 0x2c) {
		return PT_NO if $li < 10;
		if ($li > 10) {
			return PT_NO if $b->[8] == 0;
			return PT_MAYBE;
		}
		return PT_NO if $b->[8] != 0;
		return PT_YES;
	}
	if ($mt == 0x01) {
		return PT_NO if $li < 18;
		return PT_MAYBE;
	}
	if ($mt == 0x21 || $mt == 0x2b) {
		return PT_NO if $li < 14;
		return PT_MAYBE;
	}
	if ($mt == 0x02 || $mt == 0x0c || $mt == 0x2f) {
		return PT_NO if $li < 13;
		return PT_MAYBE;
	}
	if ($mt == 0x17 || $mt == 0x2d || $mt == 0x18 || $mt == 0x1a || $mt == 0x19 || $mt == 0x1b) {
		return PT_NO if $li < 12;
		return PT_MAYBE;
	}
	if ($mt == 0x07) {
		return PT_NO if $li < 11;
		if ($li > 11) {
			return PT_NO if $b->[10] == 0;
			return PT_MAYBE;
		}
		return PT_NO if $b->[10] != 0;
		return PT_YES;
	}
	if ($mt == 0x29 || $mt == 0x2a) {
		return PT_NO if $li < 11;
		return PT_MAYBE;
	}
	if ($mt == 0x28) {
		return PT_MAYBE;
	}
	if ($mt == 0x22 || $mt == 0x23 || $mt == 0xe9 || $mt == 0xea || $mt == 0xeb || $mt == 0xec || $mt == 0xed || $mt == 0xf8 || $mt == 0xfc || $mt == 0xfd || $mt == 0xfe || $mt == 0xff || $mt == 0x25 || $mt == 0x26) {
		return PT_NO;
	}
	return PT_NO;
}
#package Message;
sub checkAnsiIsup {
	my ($self,$path,$li,$b) = @_;
	my $mt = $b->[10];

	return PT_NO if $li < 11;

	if ($mt == 0x10 || $mt == 0x11 || $mt == 0x12 || $mt == 0x13 || $mt == 0x14 || $mt == 0x15 || $mt == 0x16 || $mt == 0x24 || $mt == 0x2e || $mt == 0xe9 || $mt == 0xec) {
		return PT_NO if $li != 11;
		return PT_MAYBE;
	}
	if ($mt == 0xed) {
		return PT_NO if $li < 12;
		if ($li > 12) {
			return PT_NO if $b->[11] == 0;
			return PT_MAYBE;
		}
		return PT_NO if $b->[11] != 0;
		return PT_MAYBE;
	}
	if ($mt == 0x05 || $mt == 0xea) {
		return PT_NO if $li != 12;
		return PT_MAYBE;
	}
	if (exists $mtypes{5}->{$mt}) {
		return PT_MAYBE;
	}
	return PT_MAYBE;
}


# -------------------------------------
package MyOptions;
use strict;
# -------------------------------------

#package MyOptions;
sub assign {
	my $mw = shift;
	#$mw->optionAdd('*font'=>'-*-helvetica-medium-r-*--*-120-*-*-*-*-*-*');
	#$mw->optionAdd('*.Button.*.font'=>'-*-helvetica-bold-r-*--*-120-*-*-*-*-*-*');
	#$mw->optionAdd('*.Label.*.font'=>'-*-helvetica-bold-r-*--*-120-*-*-*-*-*-*');
	#$mw->optionAdd('*font'=>'Arial 9');
	#$mw->optionAdd('*font'=>'Helvetica 10');
	#$mw->optionAdd('*Button*font'=>'Arial-Bold 9');
	#$mw->optionAdd('*Label*font'=>'Arial-Bold 9');
	#$mw->optionAdd('*disabledBackground'=>'dark grey');
	#$mw->optionAdd('*highlightBackground'=>'light grey');
	#$mw->optionAdd('*highlightThickness'=>1);
	#$mw->optionAdd('*borderThickness'=>1);
	#$mw->optionAdd('*borderWidth'=>1);
	#$mw->optionAdd('*border'=>0);
	#$mw->optionAdd('*Menu*Width'=>1);
	#$mw->optionAdd('*Menu*Height'=>1);

	$mw->optionAdd('*Balloon*font'=>'Arial 8');
	#$mw->optionAdd('*padX'=>0);
	#$mw->optionAdd('*padY'=>0);
	#$mw->optionAdd('*relief'=>'groove');
	$mw->optionAdd('*Scrollbar*Width'=>12);
}

# -------------------------------------
package MyPixmaps;
use strict;
# -------------------------------------

my $iconImage = <<EOF;
/* XPM */
static char * streams_icon_xpm[] = {
"48 48 484 2",
"  	c #575757",
". 	c #C4C4C4",
"+ 	c #FFFFFF",
"\@ 	c #FBFBFE",
"# 	c #DCDDF4",
"\$ 	c #969BDD",
"\% 	c #6B73D2",
"\& 	c #6F75D4",
"* 	c #8389D8",
"= 	c #C4C6ED",
"- 	c #ECEDF9",
"; 	c #FEFEFF",
"> 	c #F0F0F0",
", 	c #CECECE",
"' 	c #797979",
") 	c #3D3D3D",
"! 	c #313131",
"~ 	c #333333",
"{ 	c #6B6B6B",
"] 	c #CACACA",
"^ 	c #FCFCFC",
"/ 	c #FCFDFE",
"( 	c #C1C5EC",
"_ 	c #5057C8",
": 	c #434CC1",
"< 	c #8D91DB",
"[ 	c #A0A4E2",
"} 	c #8489D9",
"| 	c #4F58C8",
"1 	c #7178D4",
"2 	c #CCCFEF",
"3 	c #EFEFEF",
"4 	c #808080",
"5 	c #242424",
"6 	c #414141",
"7 	c #878787",
"8 	c #ACACAC",
"9 	c #8E8E8E",
"0 	c #3B3B3B",
"a 	c #323232",
"b 	c #C2C2C2",
"c 	c #E7E8F7",
"d 	c #4B53C7",
"e 	c #4750C7",
"f 	c #C5C8ED",
"g 	c #FAFAFD",
"h 	c #F7F7FD",
"i 	c #CCCEEF",
"j 	c #6D73D1",
"k 	c #4751C5",
"l 	c #5D5D68",
"m 	c #1A1A1A",
"n 	c #4A4A4A",
"o 	c #DADADA",
"p 	c #FBFBFB",
"q 	c #CBCBCB",
"r 	c #3E3E3E",
"s 	c #424242",
"t 	c #EAEAEA",
"u 	c #FDFDFE",
"v 	c #7E85D7",
"w 	c #3840C1",
"x 	c #B9BBEA",
"y 	c #FDFDFF",
"z 	c #E2E3EA",
"A 	c #40435F",
"B 	c #090B17",
"C 	c #72738A",
"D 	c #F0F0F4",
"E 	c #C5C5C5",
"F 	c #212121",
"G 	c #858585",
"H 	c #E2E2F6",
"I 	c #414AC4",
"J 	c #6E74D2",
"K 	c #F2F2FB",
"L 	c #F3F3F3",
"M 	c #151515",
"N 	c #525581",
"O 	c #4C53BE",
"P 	c #C6C9EE",
"Q 	c #585858",
"R 	c #454545",
"S 	c #E0E0E0",
"T 	c #AAAEE5",
"U 	c #353FBC",
"V 	c #A8ADE5",
"W 	c #FEFEFE",
"X 	c #B2B2B2",
"Y 	c #1C1C1C",
"Z 	c #636363",
"` 	c #DDDEEE",
" .	c #6D73D2",
"..	c #535BCB",
"+.	c #F0F1FB",
"\@.	c #B0B0B0",
"#.	c #B9B9B9",
"\$.	c #F9FAFE",
"\%.	c #777DD5",
"\&.	c #3940C1",
"*.	c #E5E7F8",
"=.	c #E2E2E2",
"-.	c #262626",
";.	c #DBDCF3",
">.	c #555ECA",
",.	c #7F84D6",
"'.	c #F6F7FD",
").	c #909090",
"!.	c #E8E9F8",
"~.	c #5F65CD",
"{.	c #5158C8",
"].	c #FCFCFF",
"^.	c #F8F8F8",
"/.	c #6E6E6E",
"(.	c #1F1F1F",
"_.	c #B3B3B3",
":.	c #FDFDFD",
"<.	c #B9BCE9",
"[.	c #3C45C0",
"}.	c #B5B9E9",
"|.	c #EDEDED",
"1.	c #4D4D4D",
"2.	c #686868",
"3.	c #D8D9F3",
"4.	c #4F55C9",
"5.	c #7176D4",
"6.	c #202020",
"7.	c #6F6F6F",
"8.	c #F5F5F5",
"9.	c #6E73D3",
"0.	c #6268CE",
"a.	c #E4E5F7",
"b.	c #4B4B4B",
"c.	c #ECECEC",
"d.	c #C9CCEF",
"e.	c #3E48C0",
"f.	c #8F94DC",
"g.	c #E6E6E6",
"h.	c #525252",
"i.	c #E9E9E9",
"j.	c #D3D7F3",
"k.	c #454EC6",
"l.	c #9CA1E1",
"m.	c #FCFCFE",
"n.	c #F9F9F9",
"o.	c #E7E7E7",
"p.	c #BFC2EC",
"q.	c #363FC1",
"r.	c #A2A5E2",
"s.	c #AAAAAA",
"t.	c #171717",
"u.	c #8C8C8C",
"v.	c #F6F7FC",
"w.	c #8F94DB",
"x.	c #4D56C9",
"y.	c #E9E9F9",
"z.	c #979797",
"A.	c #232323",
"B.	c #E3E3E3",
"C.	c #BBBEEA",
"D.	c #323ABF",
"E.	c #ABAEE6",
"F.	c #4F4F4F",
"G.	c #D7D7D7",
"H.	c #D1D4F1",
"I.	c #4F57C9",
"J.	c #A5AAE4",
"K.	c #9E9E9E",
"L.	c #B9BDE9",
"M.	c #2F3ABB",
"N.	c #AFB4E5",
"O.	c #C1C1C1",
"P.	c #111111",
"Q.	c #898989",
"R.	c #FBFBFD",
"S.	c #5D66CE",
"T.	c #EAECF9",
"U.	c #A4A4A4",
"V.	c #BDC1EB",
"W.	c #3C46C3",
"X.	c #B2B6E7",
"Y.	c #656565",
"Z.	c #363636",
"`.	c #CCCCCC",
" +	c #5A61CC",
".+	c #B5B7E8",
"++	c #353535",
"\@+	c #E4E4E4",
"#+	c #CBCCEE",
"\$+	c #5E64CD",
"\%+	c #B8BCEA",
"\&+	c #727272",
"*+	c #F7F7F7",
"=+	c #8C92DB",
"-+	c #989DDF",
";+	c #F3F4FB",
">+	c #DEE0F5",
",+	c #9499DD",
"'+	c #C7CAEE",
")+	c #B6B6B6",
"!+	c #676767",
"~+	c #D8DAF3",
"{+	c #9CA1E0",
"]+	c #E3E4F6",
"^+	c #BFBFBF",
"/+	c #888888",
"(+	c #EDEDF9",
"_+	c #BCBFEA",
":+	c #D3D5F1",
"<+	c #B1B1B1",
"[+	c #999999",
"}+	c #F5F5FC",
"|+	c #B9BDEA",
"1+	c #D6D8F3",
"2+	c #FAFAFB",
"3+	c #C9C9C9",
"4+	c #D0D3F0",
"5+	c #D9DBF3",
"6+	c #EEEEEE",
"7+	c #BBBBBB",
"8+	c #CBCDEF",
"9+	c #F6F6F9",
"0+	c #CDCDCD",
"a+	c #FAFAFA",
"b+	c #F1F1F1",
"c+	c #EFEFF7",
"d+	c #F4F4F4",
"e+	c #E1E1E1",
"f+	c #DEDEDE",
"g+	c #DCDCDD",
"h+	c #D2D3E3",
"i+	c #C6C7DD",
"j+	c #BFBFC1",
"k+	c #D9D9D9",
"l+	c #E8E8E8",
"m+	c #D6D8F2",
"n+	c #D4D5E5",
"o+	c #D5D5D5",
"p+	c #E5E5E5",
"q+	c #404040",
"r+	c #777777",
"s+	c #7C7C7C",
"t+	c #7D7E88",
"u+	c #6D6D79",
"v+	c #333334",
"w+	c #3C3C3C",
"x+	c #BEBEBE",
"y+	c #B5B5B5",
"z+	c #464646",
"A+	c #989898",
"B+	c #DEDFF5",
"C+	c #9495A8",
"D+	c #F6F6F6",
"E+	c #C0C0C0",
"F+	c #494949",
"G+	c #C6C6C6",
"H+	c #535353",
"I+	c #9D9D9D",
"J+	c #F2F2F2",
"K+	c #8B8B8B",
"L+	c #444444",
"M+	c #9B9B9B",
"N+	c #4E4E4E",
"O+	c #DFE0E9",
"P+	c #55555C",
"Q+	c #D3D3D3",
"R+	c #D8D8D8",
"S+	c #3A3A3A",
"T+	c #EBEBEB",
"U+	c #6D6D6D",
"V+	c #090909",
"W+	c #2E2E2E",
"X+	c #E9EAF8",
"Y+	c #7E7F8D",
"Z+	c #030303",
"`+	c #929292",
" \@	c #131313",
".\@	c #0D0D0D",
"+\@	c #474747",
"\@\@	c #6C6C6C",
"#\@	c #A2A2A2",
"\$\@	c #D1D1D1",
"\%\@	c #9C9C9C",
"\&\@	c #828282",
"*\@	c #DCDCDC",
"=\@	c #646464",
"-\@	c #57575B",
";\@	c #B8B8B8",
">\@	c #7E7E7E",
",\@	c #0F0F0F",
"'\@	c #9F9F9F",
")\@	c #666666",
"!\@	c #1D1D1D",
"~\@	c #F5F6FC",
"{\@	c #7F7F88",
"]\@	c #3F3F3F",
"^\@	c #959595",
"/\@	c #B4B4B4",
"(\@	c #343434",
"_\@	c #A3A3A3",
":\@	c #585859",
"<\@	c #252525",
"[\@	c #C3C3C3",
"}\@	c #0A0A0A",
"|\@	c #484848",
"1\@	c #6A6A6A",
"2\@	c #F6F7F8",
"3\@	c #7F8082",
"4\@	c #383838",
"5\@	c #A0A0A0",
"6\@	c #505050",
"7\@	c #5C5C5C",
"8\@	c #707070",
"9\@	c #303030",
"0\@	c #DDDDDD",
"a\@	c #696969",
"b\@	c #4B4B4E",
"c\@	c #E2E2E6",
"d\@	c #2A2A2A",
"e\@	c #161616",
"f\@	c #A5A5A5",
"g\@	c #4C4C4C",
"h\@	c #1B1B1B",
"i\@	c #D2D2D2",
"j\@	c #3F3F40",
"k\@	c #626263",
"l\@	c #8A8A8A",
"m\@	c #717171",
"n\@	c #565656",
"o\@	c #4D4E55",
"p\@	c #ABABAB",
"q\@	c #9A9A9A",
"r\@	c #7A7A7A",
"s\@	c #3C3C3F",
"t\@	c #8F8F93",
"u\@	c #969696",
"v\@	c #DFDFDF",
"w\@	c #838390",
"x\@	c #EBECF9",
"y\@	c #F7F7F8",
"z\@	c #7F7F7F",
"A\@	c #8F8F8F",
"B\@	c #97979A",
"C\@	c #787887",
"D\@	c #C4C4CA",
"E\@	c #D4D4D4",
"F\@	c #838383",
"G\@	c #CDCDCE",
"H\@	c #D1D2E4",
"I\@	c #E1E2F5",
"J\@	c #C8C8C8",
"K\@	c #CFCFD5",
"L\@	c #C4C7E6",
"M\@	c #EAEBF6",
"N\@	c #CBCBCC",
"O\@	c #E0E2F1",
"P\@	c #CDD0F0",
"Q\@	c #E4E4EA",
"R\@	c #BEC2EC",
"S\@	c #E4E6F7",
"T\@	c #B3B4B5",
"U\@	c #E7E8F6",
"V\@	c #B6B9E9",
"W\@	c #D3D5F2",
"X\@	c #A6A6A6",
"Y\@	c #ECEDF3",
"Z\@	c #AEB2E6",
"`\@	c #D5D7F2",
" #	c #8A8A8B",
".#	c #8990DB",
"+#	c #AEAEAE",
"\@#	c #F0F0F8",
"##	c #979DDF",
"\$#	c #BCBEEA",
"\%#	c #ADB2E6",
"\&#	c #525AC9",
"*#	c #C4C6EC",
"=#	c #8085D8",
"-#	c #9DA2E0",
";#	c #F8F9FD",
">#	c #DFE1F6",
",#	c #4C55C7",
"'#	c #7C83D7",
")#	c #F8F8FD",
"!#	c #626262",
"~#	c #767DD5",
"{#	c #8A90DB",
"]#	c #515151",
"^#	c #8084D6",
"/#	c #434EC2",
"(#	c #CCCFF0",
"_#	c #C7C7C7",
":#	c #A8A8A8",
"<#	c #7379D4",
"[#	c #8288D8",
"}#	c #DCDCF4",
"|#	c #333CBF",
"1#	c #858ADA",
"2#	c #F6F6FC",
"3#	c #F1F2FB",
"4#	c #6F76D3",
"5#	c #8289DA",
"6#	c #7980D6",
"7#	c #4149C4",
"8#	c #D6D7F2",
"9#	c #F0F0FA",
"0#	c #676ECF",
"a#	c #8B90DA",
"b#	c #C8CBEE",
"c#	c #4049C4",
"d#	c #8287D9",
"e#	c #686869",
"f#	c #484849",
"g#	c #5B62CC",
"h#	c #979DDE",
"i#	c #FAFBFE",
"j#	c #8C92DD",
"k#	c #323BC0",
"l#	c #ADADAD",
"m#	c #292929",
"n#	c #474FC7",
"o#	c #ABAEE5",
"p#	c #1E1E1E",
"q#	c #DEE0F4",
"r#	c #6971D0",
"s#	c #EBECF8",
"t#	c #DEDFF4",
"u#	c #BDC0EA",
"v#	c #B7B9E9",
"w#	c #333BBF",
"x#	c #9FA3E2",
"y#	c #FAFAFE",
"z#	c #373737",
"A#	c #4D54C7",
"B#	c #D2D4F1",
"C#	c #2D2D2D",
"D#	c #5F5F5F",
"E#	c #838ADA",
"F#	c #3D46C2",
"G#	c #BABDE9",
"H#	c #2B2B2B",
"I#	c #787DD5",
"J#	c #6C72D1",
"K#	c #E3E5F7",
"L#	c #676ECE",
"M#	c #4B53C6",
"N#	c #9C9EAF",
"O#	c #4B52C7",
"P#	c #9AA0E1",
"Q#	c #848484",
"R#	c #D6D9F3",
"S#	c #4A4FA5",
"T#	c #1D1D2A",
"U#	c #6F6F75",
"V#	c #9DA1E1",
"W#	c #454CC4",
"X#	c #E1E3F6",
"Y#	c #A1A1A1",
"Z#	c #E6E6E7",
"`#	c #979798",
" \$	c #3F4376",
".\$	c #4D56C4",
"+\$	c #B8BCE9",
"\@\$	c #B6B9E8",
"#\$	c #464FC2",
"\$\$	c #A6A9E3",
"\%\$	c #787878",
"\&\$	c #5A5A5A",
"*\$	c #DEDEEF",
"=\$	c #8288D7",
"-\$	c #4A52C7",
";\$	c #8388D8",
">\$	c #B8BBEA",
",\$	c #C6C8EE",
"'\$	c #979CDF",
")\$	c #F2F3FC",
"!\$	c #7B7B7B",
"~\$	c #CCCDEE",
"{\$	c #8289D7",
"]\$	c #6A72D0",
"^\$	c #6970D1",
"/\$	c #7077D4",
"(\$	c #B2B4E7",
"_\$	c #EFF0FA",
"                                                                                              . ",
"  + + + + + + + + + + + + + + \@ # \$ \% \& * = - ; + > , ' ) ! ~ { ] ^ + + + + + + + + + + + + + . ",
"  + + + + + + + + + + + + + / ( _ : < [ } | 1 2 3 4 5 6 7 8 9 0 a b + + + + + + + + + + + + + . ",
"  + + + + + + + + + + + + + c d e f g + h i j k l m n o p + ^ q r s t + + + + + + + + + + + + . ",
"  + + + + + + + + + + + + u v w x y + + + + z A B C D + + + + + E F G ^ + + + + + + + + + + + . ",
"  + + + + + + + + + + + + H I J K + + + + L G M N O P ; + + + + ^ Q R S + + + + + + + + + + + . ",
"  + + + + + + + + + + + + T U V + + + + W X Y Z `  ...+.+ + + + + \@.Y #.+ + + + + + + + + + + . ",
"  + + + + + + + + + + + \$.\%.\&.*.+ + + + =.-.n S + ;.>.,.'.+ + + + =.5 ).p + + + + + + + + + + . ",
"  + + + + + + + + + + + !.~.{.].+ + + ^./.(._.:.+ + <.[.}.; + + + |.1.2.L + + + + + + + + + + . ",
"  + + + + + + + + + + + 3.4.5.+ + + + #.6.7.8.+ + + g 9.0.a.+ + + L { b.c.+ + + + + + + + + + . ",
"  + + + + + + + + + + + d.e.f.+ + + g.h.(.i.+ + + + + j.k.l.m.+ + n.G a o.+ + + + + + + + + + . ",
"  + + + + + + + + + + + p.q.r.+ + :.s.t.u.+ + + + + + v.w.x.y.+ + :.z.A.B.+ + + + + + + + + + . ",
"  + + + + + + + + + + + C.D.E.+ + 8.F.~ G.+ + + + + + + H.I.J.+ + W K.6.=.+ + + + + + + + + + . ",
"  + + + + + + + + + + + L.M.N.+ + O.P.Q.n.+ + + + + + + R.f.S.T.+ W U.5 =.+ + + + + + + + + + . ",
"  + + + + + + + + + + + V.W.X.+ p Y.Z.`.+ + + + + + + + + #  +.+; W s.++\@++ + + + + + + + + + . ",
"  + + + + + + + + + + + #+\$+\%++ o s \&+*++ + + + + + + + + u =+-+;+:.X Q i.+ + + + + + + + + + . ",
"  + + + + + + + + + + + >+,+'+W )+!+`.+ + + + + + + + + + + ~+{+]+^ ^+/+> + + + + + + + + + + . ",
"  + + + + + + + + + + + (+_+:+8.<+[+n.+ + + + + + + + + + + }+|+1+2+3+X *++ + + + + + + + + + . ",
"  + + + + + + + + + + + }+4+5+6+7+, + + + + + + + + + + + + m.~+8+9+0+] a++ + + + + + + + + + . ",
"  + + + + + + + + + + + g >+;.o.3+b++ + + + + + + + + + + + + - i c+, o ^ + + + + + + + + + + . ",
"  + + d+e+=.n.+ i.f+f+f+g+h+i+j+7+k+l++ W f+f+f+f+l+^ + 8.e+d+h m+n+X o+:.*+=.S + |.f+o.+ + + . ",
"  + p+/.q+s r+B.s+) ) ) ) t+u+v+Z.w+1.x+^.) ) ) ) s+|.+ y+z+A+y B+C+! /+D+E+s F+G+H+) b.I+J++ . ",
"  + K+r . G+L+M+l+=.N+Q =.O+P+s Q+R+S+Y.o.M [+=.=.T+^ J+U+V+W+t X+Y+Z+F+l+`+ \@.\@+\@\@\@o #\@S+\$\@+ . ",
"  + \%\@(.\&\@X <+*\@W + Q =\@+ v.-\@0 )+;\@+\@>\@T+,\@\@\@'\@'\@0++ k+! )\@!\@s.~\@{\@Y a o+Y.]\@t.Q S+^\@;\@/\@> + . ",
"  + t K+L+(\@~ _\@p + Q =\@+ m.:\@Y H+s <\@[\@D+}\@|\@1\@1\@X + #\@! q ) 7.2\@3\@4\@4\@5\@6\@7\@(.0+8\@w+9\@n 0++ . ",
"  + ^+)+e+0\@a\@R d++ Q =\@+ p   b\@c\@o d\@^\@D+e\@f\@d+d+n.:.g\@M 9\@h\@0 i\@>\@j\@k\@{ q+' m f\@G+l+[\@S+l\@+ . ",
"  + ).<\@G A+R m\@^.+ Q =\@+ d+n\@o\@K L 0 7 d+,\@7._\@_\@O.`.h\@).3+p\@F q\@r\@s\@t\@M Y.M+e\@N+6 A+G 9\@\@.+ . ",
"  + c.u\@\@\@{ `+v\@W + M+_\@+ 3 Q.w\@x\@y\@l\@p\@d+!+!+!+!+A+;\@z\@B.+ b+A\@M+B\@C\@D\@' )+. ' E\@F\@!+m\@s.J++ . ",
"  + + p d+L a++ + + *+*++ i.G\@H\@I\@R.8.*+W J+J+J+J+*+^.d+:.+ W 3 J\@K\@L\@M\@d+a+a+d++ ^.J+8.:.+ + . ",
"  + + + + + + + + + + + + f+N\@O\@P\@;++ + + + + + + + + + + + + \@+y+Q\@R\@S\@+ + + + + + + + + + + . ",
"  + + + + + + + + + + + ^ J\@T\@U\@V\@W\@+ + + + + + + + + + + + a+O.X\@Y\@Z\@`\@; + + + + + + + + + + . ",
"  + + + + + + + + + + + 8.K. #K [ .#g + + + + + + + + + + + t r++#\@###\$#m.+ + + + + + + + + + . ",
"  + + + + + + + + + + + T+m\@2.; \%#\&#*#+ + + + + + + + + + + /\@s q K =#-#;#+ + + + + + + + + + . ",
"  + + + + + + + + + + + g.  Q + >#,#'#)#+ + + + + + + + + :.H+!#6+K ~#{#v.+ + + + + + + + + + . ",
"  + + + + + + + + + + + B.n ]#+ / ^#/#(#+ + + + + + + + + _#<\@:#W K <#[#~\@+ + + + + + + + + + . ",
"  + + + + + + + + + + + p+|\@|\@+ + }#|#1#2#+ + + + + + + d+Z z+J++ 3#4#5#2#+ + + + + + + + + + . ",
"  + + + + + + + + + + + T+N+]\@+ + ;#6#7#8#+ + + + + + + x+-.8 + + 9#0#a#)#+ + + + + + + + + + . ",
"  + + + + + + + + + + + d+Q W+W + ; b#c#d#; + + + + + 3 e#f#3 + + (+g#h#i#+ + + + + + + + + + . ",
"  + + + + + + + + + + + W U+Y |.+ + )#j#k#P\@+ + + + + l#m##.W + + !.n#o#; + + + + + + + + + + . ",
"  + + + + + + + + + + + + A\@p#0++ + + q#_ r#s#+ + + |.r 7.> + + + t#7#u#+ + + + + + + + + + + . ",
"  + + + + + + + + + + + + ;\@6.'\@+ + + W v#w#x#y#+ n.z\@z#R++ + + + _+A#B#+ + + + + + + + + + + . ",
"  + + + + + + + + + + + + 6+C#D#D++ + + m.E#F#G#^.\%\@H#E++ + + + + I#J#9#+ + + + + + + + + + + . ",
"  + + + + + + + + + + + + + m\@9\@0++ + + + K#L#M#N#S+K+^ + + + + X+O#P#; + + + + + + + + + + + . ",
"  + + + + + + + + + + + + + 0+t.Q#*++ + + ; R#S#T#U#6++ + + + ; V#W#X#+ + + + + + + + + + + + . ",
"  + + + + + + + + + + + + + n.Q.Y Y#D++ + Z#`#~  \$.\$+\$}++ + i#\@\$#\$\$\$+ + + + + + + + + + + + + . ",
"  + + + + + + + + + + + + + + l+' d\@\%\$U.A+\&\$H+f\@*\$=\$-\$;\$>\$,\$'\$\&#;\$)\$+ + + + + + + + + + + + + . ",
"  + + + + + + + + + + + + + + + 3 ;\@!\$\%\$4 <+S p + K ~\${\$]\$^\$/\$(\$_\$+ + + + + + + + + + + + + + . ",
". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . "};
EOF

#package MyPixmaps;
sub assign {
	my $mw = shift;
	$mw->Pixmap('icon', -data=>$iconImage,);
}

# -------------------------------------
package MyWidget;
use strict;
# -------------------------------------

#package MyWidget;
sub new {
	my ($type,$parent,@args) = @_;
	my $self = {};
	bless $self, $type;
	$self->{parent} = $parent;
	return $self;
}
#package MyWidget;
sub destroy {
	my ($self,@args) = @_;
	$self->SUPER::destroy(@args);
	delete $self->{parent};
	delete $self->{widget};
	delete $self->{tree};
}
#package MyWidget;
sub setframe {
	my ($self,$frame,@args) = @_;
	$self->{frame} = $frame;
	$frame->{_myobject} = $self;
	return $frame;
}
#package MyWidget;
sub setwidget {
	my ($self,$widget,@args) = @_;
	$self->{widget} = $widget;
	$widget->{_myobject} = $self;
	return $widget;
}
#package MyWidget;
sub setmainwindow {
	my ($self,$widget,@args) = @_;
	$self->setwidget($widget);
	$widget->bind('<Destroy>',
		[sub {
			my ($widget,$self,@args) = @_;
			if ($widget) {
				if ($self = $widget->{_myobject}) {
					delete $widget->{_myobject};
					$self->destroy;
				}
			}
		}, $self],
	);
	return $widget;
}
#package MyWidget;
sub parent {
	shift->{parent}
}
#package MyWidget;
sub top {
	my $self = shift;
	my $top = $self;
	while (defined $top->{parent}) {
		$top = $top->{parent};
	}
	return $top;
}
#package MyWidget;
sub toplevel {
	my $self = shift;
	if (defined $self->widget) {
		return $self->widget->toplevel;
	}
	return $self->parent->toplevel;
}
#package MyWidget;
sub widget {
	shift->{widget};
}
#package MyWidget;
sub frame {
	shift->{frame};
}
#package MyWidget;
sub attachballoon {
	my ($self,@args) = @_;
	return $self->parent->attachballoon(@args);
}
#package MyWidget;
sub statusmsg {
	my ($self,@args) = @_;
	return $self->parent->statusmsg(@args);
}
#package MyWidget;
sub configure {
	my ($self,@args) = @_;
	return $self->widget->configure(@args);
}
#package MyWidget;
sub cget {
	my ($self,@args) = @_;
	return $self->widget->cget(@args);
}
#package MyWidget;
sub pack {
	my ($self,@args) = @_;
	return $self->widget->pack(@args);
}


# -------------------------------------
package MyMainWindow;
use strict;
use vars qw(@ISA);
@ISA = qw(MyWidget);
# -------------------------------------

@MyMainWindow::windows = ();

#package MyMainWindow;
sub new {
	my ($type,$title,@args) = @_;
	my $self = MyWidget::new($type,undef,@args);
	$self->{data}->{title} = $title;
	my $mw = Tk::MainWindow->new;
	$main::mw = $mw;
	$self->setmainwindow($mw);
	$mw->title($title);
	$mw->minsize(600,400);
	$mw->geometry('1024x768');
	#$mw->protocol('WM_DELETE_WINDOW',[\&wm_delete_window,$self],);
	#$mw->protocol('WM_SAVE_YOURSELF',[\&wm_save_yourself,$self],);
	#$mw->protocol('WM_TAKE_FOCUS',   [\&wm_take_focus,   $self],);
	$mw->client(`hostname -f`);
	$mw->command("$main::progname");
	#$mw->overrideredirect(0);
	push @MyMainWindow::windows, $self;
	MyOptions::assign($mw);
	MyPixmaps::assign($mw);
	$mw->iconimage('icon');
	$mw->iconname($title);
	return $self;
}

#package MyMainWindow;
sub destroy {
	my ($self,@args) = @_;
	for (my $i = 0; $i < @MyMainWindow::windows; $i++) {
		if ($MyMainWindow::windows[$i] eq $self) {
			splice @MyMainWindow::windows, $i, 1;
			last;
		}
	}
}

#package MyMainWindow;
sub wm_delete_window {
	my ($self,@args) = @_;
}

#package MyMainWindow;
sub wm_save_yourself {
	my ($self,@args) = @_;
}

#package MyMainWindow;
sub wm_take_focus {
	my ($self,@args) = @_;
}

# -------------------------------------
package MyCanvas;
use strict;
use vars qw(@ISA);
@ISA = qw(MyWidget);
# -------------------------------------

#package MyCanvas;
sub new {
	my ($type,$parent,$width,@args) = @_;
	my $self = MyWidget::new($type,$parent,$width,@args);
	$width = 1024 unless defined $width;
	my $c = $parent->widget->Canvas(
		-confine=>1,
		-width=>$width,
		-xscrollincrement=>25,
		-yscrollincrement=>25,
		-background=>'white',
	)->pack(
		-expand=>1,
		-fill=>'both',
		-side=>'left',
		-anchor=>'w',
	);
	$self->{top} = $parent->widget;
	$self->setwidget($c);
	$main::canvas = $c;
	$self->{balloon} = $c->toplevel->Balloon(-statusbar=>$::statusbar);
	$c->update;
	$main::mycanvas = $self;
	# try creating some bindings by tag
#	$c->bind('ssp', '<ButtonPress-3>',[\&SSP::popup,Tk::Ev('b'),Tk::Ev('x'),Tk::Ev('y'),Tk::Ev('X'),Tk::Ev('Y')]);
#	$c->bind('stp', '<ButtonPress-3>',[\&STP::popup,Tk::Ev('b'),Tk::Ev('x'),Tk::Ev('y'),Tk::Ev('X'),Tk::Ev('Y')]);
#	$c->bind('scp', '<ButtonPress-3>',[\&SCP::popup,Tk::Ev('b'),Tk::Ev('x'),Tk::Ev('y'),Tk::Ev('X'),Tk::Ev('Y')]);
#	$c->bind('node','<ButtonPress-3>',[\&SP::popup,Tk::Ev('b'),Tk::Ev('x'),Tk::Ev('y'),Tk::Ev('X'),Tk::Ev('Y')]);
#	$c->bind('path','<ButtonPress-3>',[\&Path::popup,Tk::Ev('b'),Tk::Ev('x'),Tk::Ev('y'),Tk::Ev('X'),Tk::Ev('Y')]);
#	$c->bind('route','<ButtonPress-3>',[\&Route::popup,Tk::Ev('b'),Tk::Ev('x'),Tk::Ev('y'),Tk::Ev('X'),Tk::Ev('Y')]);
#	$c->bind('relation','<ButtonPress-3>',[\&Relation::popup,Tk::Ev('b'),Tk::Ev('x'),Tk::Ev('y'),Tk::Ev('X'),Tk::Ev('Y')]);
	my $w = $self->{w} = $c->width;
	my $h = $self->{h} = $c->height;
	return $self;
}

sub addballoon {
	my $self = shift;
	while (my ($item,$msg) = @_) {
		$self->{balloonmsgs}->{$item} = $msg;
		shift; shift;
	}
	$self->{balloon}->attach($self->widget,
		-balloonposition=>'mouse',
		-msg=>$self->{balloonmsgs},
	);
}

sub delballoon {
	my $self = shift;
	while (my ($item) = @_) {
		delete $self->{balloonmsgs}->{$item};
		shift;
	}
	$self->{balloon}->attach($self->widget,
		-balloonposition=>'mouse',
		-msg=>$self->{balloonmsgs},
	);
}

# unknown nodes are in columns +-7
# remote/alias SSP nodes are in columns +-6
# remote/alias SCP nodes are in columns +-5
# remote/alias STP nodes are in columns +-4 (GTT cap codes)
# remote/alias STP nodes are in columns +-3
# adjacent nodes are in columns +-2

sub colpos {
	my ($self,$col) = @_;
	my $w = $self->{w};
	my $dw = $w / 12; # 12 columns
	if ($col < 0) {
		return $col * $dw + $dw/2 + $w/2;
	} elsif ($col > 0) {
		return $col * $dw - $dw/2 + $w/2;
	} else {
		return 0 + $w/2;
	}
}

sub rowpos {
	my ($self,$row) = @_;
	my $h = $self->{h};
	return $row * 35 + $h/2;
}

# -------------------------------------
package MyTop;
use strict;
use vars qw(@ISA);
@ISA = qw(MyMainWindow);
# -------------------------------------

@MyTop::myapps = ();
$MyTop::appnum = 0;

#package MyTop;
sub new {
	my ($type,$filename,$number,@args) = @_;
	my $title = 'OpenSS7 SS7 Analyzer';
	$title .= ": $filename" if defined $filename;
	my $appno = defined $number ? $number : $MyTop::appnum;
	my $self = MyMainWindow::new($type,$title,$filename,$appno,@args);
	$self->createmenubar;
	$self->createstatusbar;
	$self->createballoon;
	$self->createcanvas;
	push @MyTop::myapps, $self;
	$MyTop::appnum = $appno if $appno > $MyTop::appnum;
	return $self;
}

#package MyTop;
sub createmenubar {
	my $self = shift;
	my $w = $self->widget;
	my ($mb,$mi,$mc);
	$mb = $self->{MenuBar} = $w->Menu(
		-type=>'menubar',
	);
	$w->configure(-menu=>$mb);
	$self->{Dialog} = $self->toplevel->Dialog(
		-buttons=>[qw/Ok Cancel Help/],
		-default_button=>'Cancel',
		-text=>'Please input capture file or interface from which to load.',
		-title=>'Source Selection',
	);
	$mi = $self->{FileMenu} = $mb->Menu(
		-tearoff=>1,
		-title=>'File Menu',
		-title=>'normal',
	);
	$mi->add('command',
		-label=>'New',
		-underline=>0,
		-command=>[\&MyTop::menuFileNew,$self],
	);
	$mi->add('command',
		-label=>'Read...',
		-underline=>0,
		-command=>[\&MyTop::menuFileRead,$self],
	);
	$mi->add('command',
		-label=>'Open...',
		-underline=>0,
		-command=>[\&MyTop::menuFileOpen,$self],
	);
	$mi->add('command',
		-label=>'Play...',
		-underline=>0,
		-command=>[\&MyTop::menuFilePlay,$self],
	);
	$mi->add('command',
		-label=>'Save',
		-underline=>0,
		-command=>[\&MyTop::menuFileSave,$self],
	);
	$mi->add('command',
		-label=>'Save As...',
		-underline=>0,
		-command=>[\&MyTop::menuFileSaveAs,$self],
	);
	$mi->add('command',
		-label=>'Close',
		-underline=>0,
		-command=>[\&MyTop::menuFileClose,$self],
	);
	$mi->add('separator');
	$mi->add('command',
		-label=>'Properties...',
		-underline=>0,
		-command=>[\&MyTop::menuFileProperties,$self],
	);
	$mc = $mi->Menu(
		-tearoff=>1,
		-title=>'Recent Files',
	);
	$mi->add('cascade',
		-menu=>$mc,
		-label=>'Recent Files...',
		-underline=>0,
		-state=>'disabled',
	);
	$self->{RecentMenu} = $mc;
	$mi->add('separator');
	$mi->add('command',
		-label=>'Exit All',
		-underline=>1,
		-command=>[\&MyTop::menuFileExitAll,$self],
	);
	$mi->add('command',
		-label=>'Debug Dump',
		-underline=>1,
		-command=>[sub {
			my $parent = shift->{FileMenu};
			my $w;
			while ($w = $parent) {
				$parent = $w->parent;
				print $w;
				foreach (@{$w->configure}) {
					print "Option: ".join(', ',@$_);
				}
			}
		}, $self],
	);
	$w->Balloon(-statusbar=>$::statusbar)->attach($mi,
		-balloonposition=>'mouse',
		-msg=>[
			"Tearoff this menu.",
			"New canvas.",
			"Read an existing capture file.",
			"Open an existing capture file.",
			"Play back a capture file in simulated real-time.",
			"Save configuration.",
			"Save configuration in another file.",
			"Close capture.",
			"Separator.",
			"Show file properties.",
			"Select recent files.",
			"Separator.",
			"Exit all windows.",
			"Dump debuging information to stdout."
		]);
	$mb->add('cascade',
		-menu=>$mi,
		-label=>'File',
		-underline=>0,
	);
	$self->{FileMenu} = $mi;
}

#package MyTop;
sub createstatusbar {
	my $self = shift;
	my $sb = $self->toplevel->Message(
		-text=>"Status bar.",
		-justify=>'left',
		-width=>'400',
		-anchor=>'w',
	);
	$sb->pack(
		-expand=>0,
		-fill=>'x',
		-side=>'bottom',
		-anchor=>'sw',
	);
	$::statusbar = $sb;
	$self->{Message} = $sb;
}

#package MyTop;
sub createballoon {
	my $self = shift;
	$_ = $self->{Balloon} = $self->toplevel->Balloon(
		#-initwait=>1000,
		-statusbar=>$self->{Message},
	);
	$::balloonwidget = $_;
	return $_;
}

#package MyTop;
sub createcanvas {
	my ($self,$width,@args) = @_;
	my $c = MyCanvas->new($self,$width,@args);
}

#package MyTop;
sub attachballoon {
	my ($self,@args) = @_;
	return $self->{Balloon}->attach(@args) if $self->{Balloon};
}
#package MyTop;
sub statusmsg {
	my ($self,$msg) = @_;
	$self->{Message}->configure(-text=>$msg) if $self->{Message};
	printf STDERR "$msg\n";
}

#package MyTop;
sub menuFileOpen {
	my $self = shift;
	my $data = $self->{data};
	my $w = $self->widget;
	my $file = $w->getOpenFile(
		-defaultextension=>'.pcap',
		-initialdir=>'./testdata',
		-initialfile=>'ss7capall.pcap',
		-title=>'Open Dialog',
	);
	return unless $file;
	my $err = '';
	my $pcap;
	unless ($pcap = Net::Pcap::pcap_open_offline($file, \$err)) {
		my $d = $w->Dialog(
			-title=>'Could not open file.',
			-text=>$err,
			-default_button=>'Ok',
			-buttons=>[ 'Ok' ],
		);
		$d->Show;
		$d->destroy;
		return;
	}
	my $network = Network->new;
#	my $fh = Net::Pcap::pcap_file($pcap);
#	Tk::Event::IO->fileevent($fh, 'readable' => [\&MyTop::readmsg,$self,$pcap,$fh,$network]);
#	$w->Busy(-recurse=>1);
	if (my $msg = Message->create($pcap)) {
		$main::begtime = $msg->{hdr};
		$main::endtime = $msg->{hdr};
		$msg->process($network);
#		$w->update;
#		if ($main::top->{updatenow}) {
#			$w->update;
#			$w->idletasks;
#			delete $main::top->{updatenow};
#		}
		while ($msg = Message->create($pcap)) {
			$main::endtime = $msg->{hdr};
			$msg->process($network);
#			$w->update;
			if ($main::top->{updatenow}) {
				$w->update;
#				$w->idletasks;
				delete $main::top->{updatenow};
			}
		}
	}
	Net::Pcap::pcap_close($pcap);
#	$w->update;
#	$w->Unbusy;
#	if ($main::top->{updatenow}) {
#		$w->update;
#		$w->idletasks;
#		delete $main::top->{updatenow};
#	}
}

#package MyTop;
sub readmsg {
	my ($self,$pcap,$fh,$network,@args) = @_;
	if (my $msg = Message->create($pcap)) {
		$msg->process($network);
	} else {
		Tk::Event::IO->fileevent($fh, 'readable' => '');
		print STDERR "closing file\n";
		Net::Pcap::pcap_close($pcap);
		print STDERR "file closed\n";
	}
}

#package MyTop;
sub menuFilePlay {
	my $self = shift;
	my $data = $self->{data};
	my $w = $self->widget;
	my $file = $w->getOpenFile(
		-defaultextension=>'.pcap',
		-initialdir=>'./testdata',
		-initialfile=>'ss7capall.pcap',
		-title=>'Play Dialog',
	);
	return unless $file;
	my $err = '';
	unless ($self->{pcap} = Net::Pcap::pcap_open_offline($file, \$err)) {
		my $d = $w->Dialog(
			-title=>'Could not open file.',
			-text=>$err,
			-default_button=>'Ok',
			-buttons=>[ 'Ok' ],
		);
		$d->Show;
		$d->destroy;
		return;
	}
	$self->{network} = Network->new;
	if (my $msg = Message->create($self->{pcap})) {
		$main::begtime = $msg->{hdr};
		$main::endtime = $msg->{hdr};
		my ($secs,$usec) = Time::HiRes::gettimeofday;
		$secs -= $msg->{hdr}->{tv_sec};
		$usec -= $msg->{hdr}->{tv_usec};
		while ($usec < 0) {
			$secs -= 1;
			$usec += 1000000;
		}
		$self->{ofs} = { tv_sec=>$secs, tv_usec=>$usec };
		$msg->process($self->{network});
		if ($msg = Message->create($self->{pcap})) {
			$self->contmsg($msg);
			return;
		}
	}
	Net::Pcap::pcap_close($self->{pcap});
	delete $self->{pcap};
}

#package MyTop;
sub contmsg {
	my ($self,$msg) = @_;
	my $w = $self->widget;
	my ($osecs,$ousec) = ($self->{ofs}->{tv_sec},$self->{ofs}->{tv_usec});
	do {
		my ($secs,$usec) = Time::HiRes::gettimeofday;
		$secs -= $osecs + $msg->{hdr}->{tv_sec};
		$usec -= $ousec + $msg->{hdr}->{tv_usec};
		while ($secs > 0 && $usec < 0) {
			$secs -= 1;
			$usec += 1000000;
		}
		if ($secs > 0 || ($secs == 0 && $usec > 0)) {
			$main::endtime = $msg->{hdr};
			$msg->process($self->{network});
		} else {
			my $ms = (-$secs*1000) + int((-$usec+999)/1000);
			$w->after($ms, [\&MyTop::contmsg, $self, $msg]);
			return;
		}

	} while ($msg = Message->create($self->{pcap}));
	Net::Pcap::pcap_close($self->{pcap});
	delete $self->{pcap};
}

# -------------------------------------
package main;
use strict;
# -------------------------------------

if (length @infiles == 0) {
	@infiles = ( $infile );
}

$top = MyTop->new;

Tk::MainLoop;

my $xml = XMLout($pc_assigments);
print $xml;

#my $handler = MyParser->new();
#my $p = XML::SAX::ParserFactory->parser(Handler => $handler);
#$p->parse_usr($filename);

exit;

1;