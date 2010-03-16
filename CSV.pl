#!/usr/bin/perl

#----------------------------------------------------------------------#
# TITLE: FEC PARSER .1alpha
#
# AUTHOR: Naveen Manivannan(naveen.manivannan <at> gmail.com)
#
# WEBSITE: http://www.nmani.com/
#
# STEPS:
#			1) Download all campaign finance data from the FEC via FTP.
#			2) Unzip & convert the fixed width files into readable CSV format.
#			3) Load it into a normalized MySQL database(loading CSV files = faster
#			   than multiple insert statements by A LOT).
#
# WARNINGS: THIS WILL TAKE A LONG TIME, REQUIRE 7GB+ OF SPACE, AND USE A LOT OF THE CPU.
#		  *NIX/OSX: Use "nohup" & "nice" the system priority down. B/w 15-20 would be nice. Haha, pun. ;);
#		   Windows: Run it before bedtime, and don't mess with it or it will CRASH.
#					Also, edit the directories to MS standard.
#
#----------------------------------------------------------------------#

#### MORE HASHES THAN WAFFLE HOUSE ####
my %trans_type = (
	'10'  => 'NON-FEDERAL RECEIPT FROM PERSONS LEVIN (L-1A)',
	'11'  => 'TRIBAL CONTRIBUTION',
	'12'  => 'NON-FEDERAL OTHER RECEIPT LEVIN (L-2)',
	'13'  => 'INAUGURAL DONATION ACCEPTED',
	'15'  => 'CONTRIBUTION',
	'15C' => 'CONTRIBUTION FROM CANDIDATE',
	'15E' => 'EARMARKED CONTRIBUTION',
	'15F' => 'LOANS FORGIVEN BY CANDIDATE',
	'15I' => 'EARMARKED INTERMEDIARY IN',
	'15J' => 'MEMO (FILER\'S % OF CONTRIBUTION GIVEN TO JOIN',
	'15T' => 'EARMARKED INTERMEDIARY TREASURY IN',
	'15Z' => 'IN-KIND CONTRIBUTION RECEIVED FROM REGISTERED',
	'16C' => 'LOANS RECEIVED FROM THE CANDIDATE',
	'16F' => 'LOANS RECEIVED FROM BANKS',
	'16G' => 'LOAN FROM INDIVIDUAL',
	'16H' => 'LOAN FROM CANDIDATE/COMMITTEE',
	'16J' => 'LOAN REPAYMENTS FROM INDIVIDUAL',
	'16K' => 'LOAN REPAYMENTS FROM CANDIDATE/COMMITTEE',
	'16L' => 'LOAN REPAYMENTS RECEIVED FROM UNREGISTERED EN',
	'16R' => 'LOANS RECEIVED FROM REGISTERED FILERS',
	'16U' => 'LOAN RECEIVED FROM UNREGISTERED ENTITY',
	'17R' => 'CONTRIBUTION REFUND RECEIVED FROM REGISTERED ',
	'17U' => 'REF/REB/RET RECEIVED FROM UNREGISTERED ENTITY',
	'17Y' => 'REF/REB/RET FROM INDIVIDUAL/CORPORATION',
	'17Z' => 'REF/REB/RET FROM CANDIDATE/COMMITTEE',
	'18G' => 'TRANSFER IN AFFILIATED',
	'18H' => 'HONORARIUM RECEIVED',
	'18J' => 'MEMO (FILER\'S % OF CONTRIBUTION GIVEN TO JOIN',
	'18K' => 'CONTRIBUTION RECEIVED FROM REGISTERED FILER',
	'18S' => 'RECEIPTS FROM SECRETARY OF STATE',
	'18U' => 'CONTRIBUTION RECEIVED FROM UNREGISTERED COMMI',
	'19'  => 'ELECTIONEERING COMMUNICATION DONATION RECEIVE',
	'19J' => 'MEMO \(ELECTIONEERING COMMUNICATION % OF DONAT',
	'20'  => 'DISBURSEMENT - EXEMPT FROM LIMITS',
	'20A' => 'NON-FEDERAL DISBURSEMENT LEVIN (L-4A) VOTER R',
	'20B' => 'NON-FEDERAL DISBURSEMENT LEVIN (L-4B) VOTER I',
	'20C' => 'LOAN REPAYMENTS MADE TO CANDIDATE',
	'20D' => 'NON-FEDERAL DISBURSEMENT LEVIN (L-4D) GENERIC',
	'20F' => 'LOAN REPAYMENTS MADE TO BANKS',
	'20G' => 'LOAN REPAYMENTS MADE TO INDIVIDUAL',
	'20R' => 'LOAN REPAYMENTS MADE TO REGISTERED FILER',
	'20V' => 'NON-FEDERAL DISBURSEMENT LEVIN (L-4C) GET OUT',
	'22G' => 'LOAN TO INDIVIDUAL',
	'22H' => 'LOAN TO CANDIDATE/COMMITTEE',
	'22J' => 'LOAN REPAYMENT TO INDIVIDUAL',
	'22K' => 'LOAN REPAYMENT TO CANDIDATE/COMMITTEE',
	'22L' => 'LOAN REPAYMENT TO BANK',
	'22R' => 'CONTRIBUTION REFUND TO UNREGISTERED ENTITY',
	'22U' => 'LOAN REPAID TO UNREGISTERED ENTITY',
	'22X' => 'LOAN MADE TO UNREGISTERED ENTITY',
	'22Y' => 'CONTRIBUTION REFUND TO INDIVIDUAL',
	'22Z' => 'CONTRIBUTION REFUND TO CANDIDATE/COMMITTEE',
	'23Y' => 'INAUGURAL DONATION REFUND',
	'24A' => 'INDEPENDENT EXPENDITURE AGAINST',
	'24C' => 'COORDINATED EXPENDITURE',
	'24E' => 'INDEPENDENT EXPENDITURE FOR',
	'24F' => 'COMMUNICATION COST FOR CANDIDATE (C7)',
	'24G' => 'TRANSFER OUT AFFILIATED',
	'24H' => 'HONORARIUM TO CANDIDATE',
	'24I' => 'EARMARKED INTERMEDIARY OUT',
	'24K' => 'CONTRIBUTION MADE TO NON-AFFILIATED',
	'24N' => 'COMMUNICATION COST AGAINST CANDIDATE (C7)',
	'24P' => 'CONTRIBUTION MADE TO POSSIBLE CANDIDATE',
	'24R' => 'ELECTION RECOUNT DISBURSEMENT',
	'24T' => 'EARMARKED INTERMEDIARY TREASURY OUT',
	'24U' => 'CONTRIBUTION MADE TO UNREGISTERED',
	'24Z' => 'IN-KIND CONTRIBUTION MADE TO REGISTERED FILER',
	'29'  => 'ELECTIONEERING COMMUNICATION DISBURSEMENT(S)'
);

my %pri_indic = (
	'C' => 'CONVENTION',
	'G' => 'GENERAL',
	'P' => 'PRIMARY',
	'R' => 'RUNOFF',
	'S' => 'SPECIAL'
);

my %report_type = (
	'10D' => 'PRE-ELECTION',
	'10G' => 'PRE-GENERAL',
	'10P' => 'PRE-PRIMARY',
	'10R' => 'PRE-RUN-OFF',
	'10S' => 'PRE-SPECIAL',
	'12C' => 'PRE-CONVENTION',
	'12G' => 'PRE-GENERAL',
	'12P' => 'PRE-PRIMARY',
	'12R' => 'PRE-RUN-OFF',
	'12S' => 'PRE-SPECIAL',
	'30D' => 'POST-ELECTION',
	'30G' => 'POST-GENERAL',
	'30P' => 'POST-PRIMARY',
	'30R' => 'POST-RUN-OFF',
	'30S' => 'POST-SPECIAL',
	'60D' => 'POST-ELECTION',
	'ADJ' => 'COMP ADJUST AMEND',
	'CA'  => 'COMPREHENSIVE AMEND',
	'M1'  => 'JANUARY MONTHLY',
	'M10' => 'OCTOBER MONTHLY',
	'M11' => 'NOVEMBER MONTHLY',
	'M12' => 'DECEMBER MONTHLY',
	'M2'  => 'FEBRUARY MONTHLY',
	'M3'  => 'MARCH MONTHLY',
	'M4'  => 'APRIL MONTHLY',
	'M5'  => 'MAY MONTHLY',
	'M6'  => 'JUNE MONTHLY',
	'M7'  => 'JULY MONTHLY',
	'M8'  => 'AUGUST MONTHLY',
	'M9'  => 'SEPTEMBER MONTHLY',
	'MY'  => 'MID-YEAR REPORT',
	'Q1'  => 'APRIL QUARTERLY',
	'Q2'  => 'JULY QUARTERLY',
	'Q3'  => 'OCTOBER QUARTERLY',
	'TER' => 'TERMINATION REPORT',
	'YE'  => 'YEAR-END',
	'90S' => 'POST INAUGURAL SUPPLEMENT',
	'90D' => 'POST INAUGURAL',
	'48H' => '48 HOUR NOTIFICATION',
	'24H' => '24 HOUR NOTIFICATION'
);

my %amd_indic = (
	'A' => 'AMENDMENT',
	'C' => 'CONSOLIDATED',
	'M' => 'MULTI-CANDIDATE',
	'N' => 'NEW',
	'S' => 'SECONDARY',
	'T' => 'TERMINATED'
);

my %incumb = (
	'I' => 'INCUMBENT',
	'C' => 'CHALLENGER',
	'O' => 'OPEN'
);

my %can_status = (
	'C' => 'STATUTORY CANDIDATE',
	'F' => 'STATUTORY CANDIDATE FOR FUTURE ELECTION',
	'N' => 'NOT YET A STATUTORY CANDIDATE',
	'P' => 'STATUTORY CANDIDATE IN PRIOR CYCLE'
);

#Only when committee type = N or Q
my %interest_grp_cat = (
	'C' => 'CORPORATION',
	'L' => 'LABOR ORGANIZATION',
	'M' => 'MEMBERSHIP ORGANIZATION',
	'T' => 'TRADE ASSOCIATION',
	'V' => 'COOPERATIVE',
	'W' => 'CORPORATION WITHOUT CAPITAL STOCK'
);

my %filing_freq = (
	'A' => 'ADMINISTRATIVELY TERMINATED',
	'D' => 'DEBT',
	'M' => 'MONTHLY FILER',
	'Q' => 'QUARTERLY FILER',
	'T' => 'TERMINATED',
	'W' => 'WAIVED'
);

my %comm_type = (
	'C' => 'COMMUNICATION COST',
	'D' => 'DELEGATE',
	'H' => 'HOUSE',
	'I' => 'INDEPENDENT EXPENDITURE',
	'N' => 'NON-PARTY / NON-QUALIFIED',
	'P' => 'PRESIDENTIAL',
	'Q' => 'QUALIFIED NON-PARTY',
	'S' => 'SENATE',
	'X' => 'NON-QUALIFIED PARTY',
	'Y' => 'QUALIFIED PARTY',
	'Z' => 'NATIONAL PARTY ORGANIZATION. NON FED ACCT.',
	'E' => 'ELECTIONEERING COMMUNICATION'
);

my %comm_des = (
	'A' => 'AUTHORIZED BY A CANDIDATE',
	'J' => 'JOINT FUND RAISER',
	'P' => 'PRINCIPAL CAMPAIGN COMMITTEE OF A CANDIDATE',
	'U' => 'UNAUTHORIZED'
);

### WTF FEC? Really? COBOL??? ###
### Three words: COMMA SEPARATED VALUES.
my %cobol = (
	']' => '0',
	'j' => '1',
	'k' => '2',
	'l' => '3',
	'm' => '4',
	'n' => '5',
	'o' => '6',
	'p' => '7',
	'q' => '8',
	'r' => '9'
);

# Not used in code currently, will be in revision to simpilfy/speed up.
# Remember hashes don't appear in the order that they're typed.
# They need an index/key and must be sorted prior. Arrays don't
# but that would require 2+ nested loops for the algorithm
# this would only create 1 thus faster in second version.
my %dt_new = (
	'cn' => {
		'can_id'        => '9',
		'can_name'      => '38',
		'party1'        => '3',
		'filler1'       => '3',
		'party3'        => '3',
		'incumb'        => '1',
		'filler2'       => '1',
		'can_status'    => '1',
		'street1'       => '34',
		'street2'       => '34',
		'city'          => '18',
		'state'         => '2',
		'zipcode'       => '5',
		'camp_comm_id'  => '9',
		'elect_yr'      => '2',
		'curr_district' => '2'
	},

	'cm' => {
		'comm_id'          => '8',
		'comm_name'        => '90',
		'treasurer_name'   => '38',
		'street1'          => '34',
		'street2'          => '34',
		'city'             => '18',
		'state'            => '2',
		'zipcode'          => '5',
		'comm_des'         => '1',
		'comm_type'        => '1',
		'comm_party'       => '3',
		'file_freq'        => '1',
		'interest_grp_cat' => '1',
		'conn_org_name'    => '38',
		'can_id'           => '9'
	},

	'indiv' => {
		'filer_id'    => '9',
		'amd_indic'   => '1',
		'report_type' => '3',
		'pri_indic'   => '1',
		'micro_film'  => '11',
		'trans_type'  => '3',
		'name'        => '34',
		'city'        => '18',
		'state'       => '2',
		'zipcode'     => '5',
		'occupation'  => '35',
		'trans_month' => '2',
		'trans_day'   => '2',
		'trans_cent'  => '2',
		'trans_yr'    => '2',
		'amt'         => '7',
		'other_id'    => '9',
		'fec_num'     => '7'
	},

	'pas2' => {
		'filer_id'    => '9',
		'amd_indic'   => '1',
		'report_type' => '3',
		'pri_indic'   => '1',
		'micro_film'  => '11',
		'trans_type'  => '3',
		'trans_month' => '2',
		'trans_day'   => '2',
		'trans_cent'  => '2',
		'trans_yr'    => '2',
		'amt'         => '7',
		'other_id'    => '9',
		'can_id'      => '9',
		'fec_num'     => '7'
	},

	'oth' => {
		'filer_id'    => '9',
		'amd_indic'   => '1',
		'report_type' => '3',
		'pri_indic'   => '1',
		'micro_film'  => '11',
		'trans_type'  => '3',
		'name'        => '34',
		'city'        => '18',
		'state'       => '2',
		'zipcode'     => '5',
		'occupation'  => '35',
		'trans_month' => '2',
		'trans_day'   => '2',
		'trans_cent'  => '2',
		'trans_yr'    => '2',
		'amt'         => '7',
		'other_id'    => '9',
		'fec_num'     => '7'
	}
);

### LETS GET TO WORK ####
use Archive::Extract;

my @dirfiles = (
	"1978_EC", "1980_EC", "1982_EC", "1986_EC", "1988_EC", "1990_EC",
	"1992_EC", "1994_EC", "1996_EC", "1998_EC"
);

my @disorg = ( "cm", "cn", "pas2", "oth", "indiv" );

my @basefor = (
	"cm_dictionary.txt",    "cn_dictionary.txt",
	"indiv_dictionary.txt", "pas2_dictionary.txt",
	"oth_dictionary.txt"
);
my $tempfold = "/home/naveen/FEC/fectemp";    ### CHANGE THE CWD!! ###

# Initialize
mkdir( "$tempfold", 0777 ) || print $! . "\n";
chdir("$tempfold") || print $! . "\n";

# for ($count = 1; $count <4;  $count=$count+2){
# mkdir ("fectemp/" . (2000 + $count));
# }

# Save you lots of time.
if ($ARGV[0] eq "dl_skip"){goto (PROCESS_DATA)}

# Login FTP & Download EVERYTHING, Takes forever
use Net::FTP;
my $ftp = Net::FTP->new( "ftp.fec.gov", Debug => 0 )
  or die "Cannot connect to FEC FTP Server: $@";

$ftp->login( "anonymous", '-anonymous@' ) or die "Cannot login ", $ftp->message;

$ftp->binary();

# IMPORTANT: Text files (.txt, .csv., ect..)
# (the FEC site = UNIX based). EOF and EOL changes with Windows..
# when downloading directly to Windows.
# Google for problem resolution. Hint: "^M"

$ftp->cwd("/FEC")
  or die "Cannot change directory to FEC ", $ftp->message;

# Get the recent Format Description
foreach (@basefor) {
	print("Downloading: $_ ... ");
	$ftp->get($_);
	print("Done \n");
}

# Search the directories and look for the files that matter.
foreach (@dirfiles) {
	$ftp->cwd($_);
	foreach my $files ( $ftp->ls("") ) {
		if ( $files =~ m/^(cm|cn|indiv|pas2|oth|it)/i ) {
			if (-e "$files") { next }
			print "Downloading: $files ... ";
			$ftp->get($files) or die $ftp->message;
			print "Done \n";
		}
	}
	$ftp->cwd("/FEC");
}
print("\n Now for more recent data! \n ");

# 20xx data is located in main directory. Easier this way.
foreach (@disorg) {
	my $type = $_;
	for ( my $temp = 2000 ; $temp <= 2010 ; $temp += 2 ) {
		my $hmm = $type . substr( $temp, 2, 2 );
		if (-e "$hmm.zip") { next }
		if (-e "$hmm.txt") { next }
		print "$hmm.zip \n";
		$ftp->get( "$hmm.zip" ) or die $ftp->message;
		# print "$hmm.txt \n";
		# $ftp->get( "$hmm.txt" ) or warn $ftp->message; ## FEC BROKE THIS. WILL FIX LATER
		print( "Downloaded: " . "$hmm.zip/txt \n" );
	}
}

$ftp->quit;

PROCESS_DATA:

print("Processing data.. \n");
chdir("/home/naveen/FEC/fectemp") || print $! "\n";
open( SQL, ">", "FEC_load.sql" );

foreach (@disorg) {
	my $type = $_;
	for ( my $temp = 2000 ; $temp <= 2008 ; $temp += 2 ) {
		my $hmm = $type . substr( $temp, 2, 2 );

		print("Unziping $hmm.zip \n");
		extract_zip("$hmm.zip");
		print("Unzipped $hmm.zip \n");
		print("Processing $hmm data \n");
		&$type($hmm);    #This is why perl rocks.
		my $sql_txt = build_sql($hmm);
		print("Adding $hmm build to FEC_load.sql \n");
		print( SQL $sql_txt );

	}

}

close(SQL);

### SUBROUTINES ###
sub extract_zip {

	my $ae = Archive::Extract->new( archive => $_[0] )
	  or die "FAILED TO LOAD ZIP: $_[0] \n";

	$ae->extract or die "FAILED TO LOAD: $_[0] \n";

}

sub removecobol {

	# A lot less CPU intensive than regex.
	# Remember, the first character is 1, not 0.

	local ( $a, $b );
	$a = length( $_[0] );
	$b = substr( $_[0], $a, 1 );

	print $b;

	if ( $cobol{$b} eq "" ) {
		1 * $_[0];
	}
	else {
		-1 * substr( $_[0], 1, $a - 1 ) . $cobol{$b};
	}
}

sub array2quotes {

	# Input array of variables and it'll output quotations.
	# ie- Jack John Jill turns into '"Jack", "John" , "Jill";

	local ( $a, $b );

	foreach (@_) {
		$b = trim($_);
		$a = $a . qq("$b") . ',';
	}

	chop($a);
	$a = $a . "\n";
	return $a;
}

sub rev_name {

	# ie "Smith, John" to "John Smith". [1] = last name, [2] = first name
	# Otherwise everything = last name.
	# Once again, faster this way than regex.
	# Upcoming updates: 1) will find Mr/Dr./JD and put in column.
	# 	2) Find professional titles(CPA, JD, MD, ect..)
	#	3) Will separate full names. ie- "John Smith" to "John", "Smith"

	local (@a);
	@a =
	  split( /,/, $_[0] )
	  ;    # We could trim here but will cause problems with nested subroutines.
	return @a;

}

sub rev_occupation {

	# ie "Smith, John" to "John Smith". [0] = last name, [1] = first name
	# Once again, faster this way than regex.

	local (@a);
	@a =
	  split( /\//, $_[0] )
	  ;    # We could trim here but will cause problems with nested subroutines.
	return @a;

}

sub trim($)
### Perl has no TRIM unlike PHP. Found these online as my method was SLOOOW.###
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub ltrim($) {
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}

sub rtrim($) {
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}

sub cn {

	local (
		$can_id,       $can_name, @names,         $party1,
		$party3,       $incumb,   $can_status,    $street1,
		$street2,      $city,     $state,         $zipcode,
		$camp_comm_id, $elect_yr, $curr_district, $output_line
	);

	$[ = 1
	  ; ## VERY VERY Important, or else perl will use 0 as default starting for substr.

	open( CN,     "<", "foiacn.dta" ) or die "Could not open. $1 \n";
	open( CN_CSV, ">", "$_[0].csv" )  or die "Cannot write $_[0].csv \n";
	while ( my $line = <CN> ) {
		chomp($line);    # Could use just "chomp;"

		# You could thise using another loop, but this is already in a loop.
		# More loops = more processing.

		$can_id   = substr( $line, 1,  9 );
		$can_name = substr( $line, 10, 38 );
		@names    =
		  rev_name($can_name);  ## REMEMBER: perl is starting w/ 1 now, not 0!!!
		$party1 = substr( $line, 48, 3 );

		#filer1 = substr($line, 51, 1) for older data file(pre-2000s).;
		$party3 = substr( $line, 54, 3 );
		$incumb = substr( $line, 57, 1 );

		#filer2 = substr($line, 58, 1) for older data file(pre-2000s);
		$can_status    = substr( $line, 59,  1 );
		$street1       = substr( $line, 60,  34 );
		$street2       = substr( $line, 94,  34 );
		$city          = substr( $line, 128, 18 );
		$state         = substr( $line, 146, 2 );
		$zipcode       = substr( $line, 148, 5 );
		$camp_comm_id  = substr( $line, 153, 9 );
		$elect_yr      = substr( $line, 162, 2 );
		$curr_district = substr( $line, 164, 2 );

		$output_line = &array2quotes(
			$can_id,       $names[2], $names[1],   $party1,
			$party3,       $incumb,   $can_status, $street1,
			$street2,      $city,     $state,      $zipcode,
			$camp_comm_id, $elect_yr, $curr_district
		);

		print( CN_CSV "$output_line" );
	}
	close(CN_CSV);
	close(CN);

	$[ = 0;    ## Switching it back because I like it that way.
	unlink("foiacn.dta");
};

sub cm {

	local (
		$comm_id,          $comm_name,     $treasurer_name, $street1,
		$street2,          $city,          $state,          $zipcode,
		$comm_des,         $comm_type,     $comm_party,     $file_req,
		$interest_grp_cat, $conn_org_name, $can_id,         $output_line
	);

	$[ = 1
	  ; ## VERY VERY Important, or else perl will use 0 as default starting for substr.

	open( CM,     "<", "foiacm.dta" ) or die "Could not open. $1 \n";
	open( CM_CSV, ">", "$_[0].csv" )  or die "Cannot write $_[0].csv \n";

	while ( my $line = <CM> ) {
		chomp($line);    # Could use just "chomp;"

		# You could thise using another loop, but this is already in a loop.
		# More loops = more processing.

		$comm_id        = substr( $line, 1,   9 );
		$comm_name      = substr( $line, 10,  90 );
		$treasurer_name = substr( $line, 100, 38 );
		@names          =
		  rev_name($treasurer_name)
		  ;              ## REMEMBER: perl is starting w/ 1 now, not 0!!!
		$street1          = substr( $line, 138, 34 );
		$street2          = substr( $line, 172, 34 );
		$city             = substr( $line, 206, 18 );
		$state            = substr( $line, 224, 2 );
		$zipcode          = substr( $line, 226, 5 );
		$comm_des         = substr( $line, 231, 1 );
		$comm_type        = substr( $line, 232, 1 );
		$comm_party       = substr( $line, 233, 3 );
		$file_freq        = substr( $line, 236, 1 );
		$interest_grp_cat = substr( $line, 237, 1 );
		$conn_org_name    = substr( $line, 238, 38 );
		$can_id           = substr( $line, 276, 9 );

		$output_line = &array2quotes(
			$comm_id,  $comm_name,        $name[2],
			$name[1],  $street1,          $street2,
			$city,     $state,            $zipcode,
			$comm_des, $comm_type,        $comm_party,
			$file_req, $interest_grp_cat, $conn_org_name,
			$can_id
		);

		print( CM_CSV "$output_line" );
	}
	close(CM_CSV);
	close(CM);

	$[ = 0;    ## Switching it back because I like it that way.
	unlink("foiacm.dta");
}

sub oth {

	local (
		$filer_id,   $amd_indic,   $report_type, $pri_indic,  $micro_film,
		$trans_type, $oth_name,    $city,        $state,      $zipcode,
		$job,        $trans_month, $trans_day,   $trans_cent, $trans_yr,
		$amt,        $other_id,    $fec_num,     $output_line
	);

	$[ = 1
	  ; ## VERY VERY Important, or else perl will use 0 as default starting for substr.

	open( OTH,     "<", "itoth.dta" ) or die "Could not open. $1 \n";
	open( OTH_CSV, ">", "$_[0].csv" ) or die "Cannot write $_[0].csv \n";
	while ( my $line = <OTH> ) {
		chomp($line);    # Could use just "chomp;"

		# You could thise using another loop, but this is already in a loop.
		# More loops = more processing.

		$filer_id    = substr( $line, 1,  9 );
		$amd_indic   = substr( $line, 10, 1 );
		$report_type = substr( $line, 11, 3 );
		$pri_indic   = substr( $line, 14, 1 );
		$micro_film  = substr( $line, 15, 11 );    ## REALLY?
		$trans_type  = substr( $line, 26, 3 );
		$oth_name    = substr( $line, 29, 34 );
		$city        = substr( $line, 63, 18 );
		$state       = substr( $line, 81, 2 );
		$zipcode     = substr( $line, 83, 5 );
		$occupation  = substr( $line, 88, 35 );
		@job         = rev_occupation($occupation);
		$trans_month = substr( $line, 123, 2 );
		$trans_day   = substr( $line, 235, 2 );
		$trans_cent  = substr( $line, 127, 2 );
		$trans_yr    = substr( $line, 129, 2 );
		$amt         = substr( $line, 131, 7 );
		$amt         = removecobol($amt);             # Who uses COBOL anymore?
		$other_id    = substr( $line, 138, 9 );
		$fec_num     = substr( $line, 147, 7 );

		$output_line = &array2quotes(
			$filer_id,    $amd_indic,  $report_type, $pri_indic,
			$micro_film,  $trans_type, $oth_name,    $city,
			$state,       $zipcode,    $job[1],      $job[2],
			$trans_month, $trans_day,  $trans_cent,  $trans_yr,
			$amt,         $other_id,   $fec_num
		);

		print( OTH_CSV "$output_line" );
	}
	close(OTH_CSV);
	close(OTH);

	$[ = 0;    ## Switching it back because I like it that way.
	unlink("itoth.dta");
}

sub pas2 {

	local (
		$filer_id,   $amd_indic,   $report_type, $pri_indic,  $micro_film,
		$trans_type, $trans_month, $trans_day,   $trans_cent, $trans_yr,
		$amt,        $other_id,    $can_id,      $fec_num
	);

	$[ = 1
	  ; ## VERY VERY Important, or else perl will use 0 as default starting for substr.

	open( PAS2,     "<", "itpas2.dta" ) or die "Could not open. $1 \n";
	open( PAS2_CSV, ">", "$_[0].csv" )  or die "Cannot write $_[0].csv \n";
	while ( my $line = <PAS2> ) {
		chomp($line);    # Could use just "chomp;"

		# You could thise using another loop, but this is already in a loop.
		# More loops = more processing.

		$filer_id    = substr( $line, 1,  9 );
		$amd_indic   = substr( $line, 10, 1 );
		$report_type = substr( $line, 11, 3 );
		$pri_indic   = substr( $line, 14, 1 );
		$micro_film  = substr( $line, 15, 11 );    ## REALLY?
		$trans_type  = substr( $line, 26, 3 );
		$trans_month = substr( $line, 29, 2 );
		$trans_day   = substr( $line, 31, 2 );
		$trans_cent  = substr( $line, 33, 2 );
		$trans_yr    = substr( $line, 35, 2 );
		$amt         = substr( $line, 37, 7 );
		$amt      = removecobol($amt);             # Who uses COBOL anymore?
		$other_id = substr( $line, 44, 9 );
		$can_id   = substr( $line, 53, 9 );
		$fec_num  = substr( $line, 62, 7 );

		$output_line = &array2quotes(
			$filer_id,   $amd_indic,  $report_type, $pri_indic,
			$micro_film, $trans_type, $trans_month, $trans_day,
			$trans_cent, $trans_yr,   $amt,         $other_id,
			$can_id,     $fec_num
		);

		print( PAS2_CSV "$output_line" );
	}
	close(PAS2_CSV);
	close(PAS2);

	$[ = 0;    ## Switching it back because I like it that way.
	unlink("itpas2.dta");
}

sub indiv {

	local (
		$filer_id,   $amd_indic,   $report_type, $pri_indic,  $micro_film,
		$trans_type, @names,       $city,        $state,      $zipcode,
		$jobs,       $trans_month, $trans_day,   $trans_cent, $name,
		$trans_yr,   $amt,         $other_id,    $fec_num
	);

	$[ = 1
	  ; ## VERY VERY Important, or else perl will use 0 as default starting for substr.

	open( INDIV,     "<", "itcont.dta" ) or die "Could not open. $1 \n";
	open( INDIV_CSV, ">", "$_[0].csv" )  or die "Cannot write $_[0].csv \n";
	while ( my $line = <INDIV> ) {
		chomp($line);    # Could use just "chomp;"

		# You could thise using another loop, but this is already in a loop.
		# More loops = more processing.

		$filer_id    = substr( $line, 1,  9 );
		$amd_indic   = substr( $line, 10, 1 );
		$report_type = substr( $line, 11, 3 );
		$pri_indic   = substr( $line, 14, 1 );
		$micro_film  = substr( $line, 15, 11 );    ## REALLY?
		$trans_type  = substr( $line, 26, 3 );
		$name        = substr( $line, 29, 34 );
		@names       = rev_name($name);
		$city        = substr( $line, 63, 18 );
		$state       = substr( $line, 81, 2 );
		$zipcode     = substr( $line, 83, 5 );
		$occupation  = substr( $line, 88, 35 );
		@job         = rev_occupation($occupation);
		$trans_month = substr( $line, 123, 2 );
		$trans_day   = substr( $line, 125, 2 );
		$trans_cent  = substr( $line, 127, 2 );
		$trans_yr    = substr( $line, 129, 2 );
		$amt         = substr( $line, 131, 7 );
		$amt         = removecobol($amt);             # Who uses COBOL anymore?
		$other_id    = substr( $line, 138, 9 );
		$fec_num     = substr( $line, 147, 7 );

		$output_line = &array2quotes(
			$filer_id,   $amd_indic,   $report_type, $pri_indic,
			$micro_film, $trans_type,  $names[2],    $names[1],
			$city,       $state,       $zipcode,     $job[1],
			$job[2],     $trans_month, $trans_day,   $trans_cent,
			$trans_yr,   $amt,         $other_id,    $fec_num
		);

		print( INDIV_CSV "$output_line" );
	}
	close(INDIV_CSV);
	close(INDIV);

	$[ = 0;    ## Switching it back because I like it that way.
	unlink("itcont.dta");
}

sub build_sql {

	local ($a);

	if ( $_[0] =~ m/^cn/i ) {
		$a = "create table $_[0] (
can_id VARCHAR(9) PRIMARY KEY,
f_name VARCHAR(38),
l_name VARCHAR(38),
party1 VARCHAR(3),
party3 VARCHAR(3),
incumb VARCHAR(1),
can_status VARCHAR(1),
street1 VARCHAR(34),
street2 VARCHAR(34),
city VARCHAR(18),
zipcode VARCHAR(5),
camp_comm_id VARCHAR(9),
elect_yr VARCHAR(2),
curr_district VARCHAR(2)
); \n \n


load data local infile \'$_[0].csv\' into table $_[0]
fields terminated by \',\'
enclosed by \'\"\'
lines terminated by \'\\n\'
(can_id, f_name, l_name, party1,
party3, incumb, can_status, street1,
street2, city, zipcode, camp_comm_id,
elect_yr, curr_district); \n \n
";

	}
	elsif ( $_[0] =~ m/^cm/i ) {
		$a = "create table $_[0] (
comm_id VARCHAR(9),
comm_name VARCHAR(90),
treas_f_name VARCHAR(38),
treas_l_name VARCHAR(38),
street1 VARCHAR(34),
street2 VARCHAR(34),
city VARCHAR(18),
state VARCHAR(2),
zipcode VARCHAR(5),
comm_des VARCHAR(1),
comm_type VARCHAR(1),
comm_party VARCHAR(3),
file_freq VARCHAR(1),
interest_grp_cat VARCHAR(38),
can_id VARCHAR(9)
); \n \n


load data local infile \'$_[0].csv\' into table $_[0]
fields terminated by \',\'
enclosed by \'\"\'
lines terminated by \'\\n\'
(comm_id, comm_name, treas_f_name, treas_l_name, street1,
street2, city, state, zipcode, comm_des, comm_type, comm_party,
file_freq, interest_grp_cat, can_id); \n \n
";
	}
	elsif ( $_[0] =~ m/^oth/i ) {
		$a = "create table $_[0] (
filer_id VARCHAR(9),
amd_indic VARCHAR(1),
report_type VARCHAR(3),
pri_indic VARCHAR(1),
micro_film VARCHAR(11),
trans_type VARCHAR(3),
oth_name VARCHAR(34),
city VARCHAR(18),
state VARCHAR(2),
zipcode VARCHAR(5),
employer VARCHAR(35),
job_title VARCHAR(35),
trans_month VARCHAR(2),
trans_day VARCHAR(2),
trans_cent VARCHAR(2),
trans_yr VARCHAR(2),
amt MEDIUMINT(7),
other_id VARCHAR(9),
fec_num VARCHAR(7)
); \n \n


load data local infile \'$_[0].csv\' into table $_[0]
fields terminated by \',\'
enclosed by \'\"\'
lines terminated by \'\\n\'
(filer_id, amd_indic, report_indic, pri_indic, micro_film, trans_type,
oth_name, city, state, zipcode, employer, job_title, trans_month, trans_day,
trans_cent, trans_yr, amt, other_id, fec_num); \n \n";
	}
	elsif ( $_[0] =~ m/^pas2/i ) {
		$a = "create table $_[0] (
filer_id VARCHAR(9),
amd_indic VARCHAR(1),
report_type VARCHAR(3),
pri_indic VARCHAR(1),
micro_film VARCHAR(11),
trans_type VARCHAR(3),
trans_month VARCHAR(2),
trans_day VARCHAR(2),
trans_cent VARCHAR(2),
trans_yr VARCHAR(2),
amt MEDIUMINT(7),
other_id VARCHAR(9),
fec_num VARCHAR(7)
); \n \n


load data local infile \'$_[0].csv\' into table $_[0]
fields terminated by \',\'
enclosed by \'\"\'
lines terminated by \'\\n\'
(filer_id, amd_indic, report_type, pri_indic, micro_film, trans_type, trans_month,
trans_day, trans_cent, trans_yr, amt, other_id, fec_num); \n \n";
	}
	elsif ( $_[0] =~ m/^indiv/i ) {
		$a = "create table $_[0] (
filer_id VARCHAR(9),
amd_indic VARCHAR(1),
report_type VARCHAR(3),
pri_indic VARCHAR(1),
micro_film VARCHAR(11),
trans_type VARCHAR(3),
f_name VARCHAR(34),
l_name VARCHAR(34),
city VARCHAR(18),
state VARCHAR(2),
zipcode VARCHAR(5),
employer VARCHAR(35),
job_title VARCHAR(35),
trans_month VARCHAR(2),
trans_day VARCHAR(2),
trans_cent VARCHAR(2),
trans_yr VARCHAR(2),
amt MEDIUMINT(7),
other_id VARCHAR(9),
fec_num VARCHAR(7)
); \n \n


load data local infile \'$_[0].csv\' into table $_[0]
fields terminated by \',\'
enclosed by \'\"\'
lines terminated by \'\\n\'
(filer_id, amd_indic, report_type, pri_indic, micro_film, trans_type, f_name,
l_name, city, state, zipcode, employer, job_title, trans_month, trans_day, trans_cent,
trans_yr, amt, other_id, fec_num); \n \n";
	}
	else { $a = "UNABLE TO CREATE .SQL FILE"; }

	return $a;
}
