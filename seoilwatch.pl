#!/usr/bin/perl -w

use strict;
use WWW::Mechanize;
use Data::Dumper;
use YAML::Tiny;

my $config_location = "/etc/seoilwatch.yml";
my $yaml = YAML::Tiny->new;
$yaml = YAML::Tiny->read($config_location);
unless ($yaml) {
   print "Failed to load config from $config_location \n";
   exit;
}

my $login = $yaml->[0]->{login};
my $password = $yaml->[0]->{password};
my $highmark = $yaml->[0]->{highmark};
my $lowmark = $yaml->[0]->{lowmark};
my $alertemail = $yaml->[0]->{alertemail};

my $url = "https://info.santaenergy.com/";

my $date = `date`;
chomp($date);
print $date . ",";

# login
my $mech = WWW::Mechanize->new();
$mech->cookie_jar(HTTP::Cookies->new);
$mech->get($url);
$mech->set_visible( $login, $password );
$mech->click('cmdLogin');
die unless ($mech->success);
my $output = $mech->content;
my @lines = split('\n',$output);
#print @lines;

my $near=0;
foreach my $line (@lines) {
    if ($near==2) {
       print "Daily price -> " .  &format($line);
       my $dailyprice = &format($line);
       $dailyprice =~ s/\$//g;
       if ($dailyprice > $highmark) {
           print " -ALERT- Daily price is over highmark.";
           my $cmd = "/bin/echo oil over highmark at $dailyprice | mail $alertemail";
           `$cmd`;
       }
       if ($dailyprice < $lowmark) {
           print " -ALERT- Daily price under lowmark.";
           my $cmd = "/bin/echo oil under lowmark at $dailyprice | mail $alertemail";
           `$cmd`;
       }
       $near=0;
    }
    if ($line =~ /Your Price If Delivered Today/) {
          $near++;
    };
}; # end each line

$mech->get("https://info.santaenergy.com/priceprotection");
my $priceprotections = $mech->content;
@lines = split('\n',$priceprotections);

$near=0;
foreach my $line (@lines) {
    if ($near==1) {
       $near++;
       next;
    }
    if ($near==2) {
       print "pre-buy price -> " .  &format($line);
       $near=0;
    }
    if ($line =~ /Pre-buy Price/) {
          $near=1;
    };
}; # end each line


# ------------ subs ----------
sub format {
 my $input = shift;
 $input =~ s/<td.*">//g;
 $input =~ s/<\/td>.*//g;
 $input =~ s/<td.*">//g;
 $input =~ s/<\/td>.*//g;
 return $input;
}

print "\n";

