#!/usr/bin/perl -l
use warnings;
use strict;

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

use Term::ReadKey qw/ReadMode ReadKey/;
use File::Temp qw/tempfile/;

$/ = ""; # paragraph mode

my $SVN = $ENV{SVN} || 'svn'; # passed unquoted to sh
my $VIM = 'vim';
my $STATUS = './STATUS';
my $BRANCHES = '^/subversion/branches';

sub usage {
  my $basename = $0;
  $basename =~ s#.*/##;
  print <<EOF;
Run this from the root of your release branch (e.g., 1.6.x) working copy.

For each entry in STATUS, you will be prompted whether to merge it.

WARNING:
If you accept the prompt, $basename will revert all local changes and will
commit the merge immediately.

The 'svn' binary defined by the environment variable \$SVN, or otherwise the
'svn' found in \$PATH, will be used to manage the working copy.
EOF
}

sub prompt {
  local $\; # disable 'perl -l' effects
  print "Go ahead? ";

  # TODO: this part was written by trial-and-error
  ReadMode 'cbreak';
  my $answer = (ReadKey 0);
  print $answer, "\n";
  return ($answer =~ /^y/i) ? 1 : 0;
}

sub merge {
  my %entry = @_;

  my ($logmsg_fh, $logmsg_filename) = tempfile();
  my $mergeargs;

  my $backupfile = "backport_pl.$$.tmp";

  if ($entry{branch}) {
    $mergeargs = "--reintegrate $BRANCHES/$entry{branch}";
    print $logmsg_fh "Reintergrate the $BRANCHES/$entry{branch} branch:";
    print $logmsg_fh "";
  } else {
    $mergeargs = join " ", (map { "-c$_" } @{$entry{revisions}}), '^/subversion/trunk';
    if (@{$entry{revisions}} > 1) {
      print $logmsg_fh "Merge the r$entry{revisions}->[0] group from trunk:";
      print $logmsg_fh "";
    } else {
      print $logmsg_fh "Merge r$entry{revisions}->[0] from trunk:";
      print $logmsg_fh "";
    }
  }
  print $logmsg_fh $_ for @{$entry{entry}};
  close $logmsg_fh or die "Can't close $logmsg_filename: $!";

  my $script = <<"EOF";
#!/bin/sh
set -e
$SVN diff > $backupfile
$SVN revert -R .
$SVN up
$SVN merge $mergeargs
$VIM -e -s -n -N -i NONE -u NONE -c '/^ [*] r$entry{revisions}->[0]/normal! dap' -c wq $STATUS
$SVN commit -F $logmsg_filename
EOF

  $script .= <<"EOF" if $entry{branch};
reinteg_rev=\`$SVN info $STATUS | sed -ne 's/Last Changed Rev: //p'\`
$SVN rm $BRANCHES/$entry{branch}\
        -m "Remove the '$entry{branch}' branch, reintegrated in r\$reinteg_rev."
EOF

  open SHELL, '|-', qw#/bin/sh -x# or die $!;
  print SHELL $script;
  close SHELL or warn "$0: sh($?): $!";

  unlink $backupfile if -z $backupfile;
  unlink $logmsg_filename unless $? or $!;
}

# TODO: may need to parse other headers too?
sub parse_entry {
  my @lines = @_;
  my (@revisions, @logsummary, $branch, @votes);
  # @lines = @_;

  # strip first three spaces
  $_[0] =~ s/^ \* /   /;
  s/^   // for @_;

  # revisions
  while ($_[0] =~ /^r/) {
    while ($_[0] =~ s/^r(\d+)(?:,\s*)?//) {
      push @revisions, $1;
    }
    shift;
  }

  # summary
  push @logsummary, shift until $_[0] =~ /^\w+:/;

  # votes
  unshift @votes, pop until $_[-1] =~ /^Votes:/;
  pop;

  # branch
  while (@_) {
    shift and next unless $_[0] =~ s/^Branch:\s*//;
    $branch = (shift || shift || die "Branch header found without value");
    $branch =~ s#.*/##;
    $branch =~ s/^\s*//;
    $branch =~ s/\s*$//;
  }

  return (
    revisions => [@revisions],
    logsummary => [@logsummary],
    branch => $branch,
    votes => [@votes],
    entry => [@lines],
  );
}

sub handle_entry {
  my %entry = parse_entry @_;

  print "";
  print "\n>>> The r$entry{revisions}->[0] group:";
  print join ", ", map { "r$_" } @{$entry{revisions}};
  print "$BRANCHES/$entry{branch}" if $entry{branch};
  print "";
  print for @{$entry{logsummary}};
  print "";
  print for @{$entry{votes}};
  print "";
  print "Vetoes found!" if grep { /^  -1:/ } @{$entry{votes}};

  # TODO: this changes ./STATUS, which we're reading below, but
  #       on my system the loop in main() doesn't seem to care.
  merge %entry if prompt;

  1;
}

sub main {
  usage, exit 0 if @ARGV;
  usage, exit 1 unless -r $STATUS;

  @ARGV = $STATUS;
  while (<>) {
    my @lines = split /\n/;

    # Section header?
    print "\n\n=== $lines[0]" and next if $lines[0] =~ /^[A-Z].*:$/i;

    # Backport entry?
    handle_entry @lines and next if $lines[0] =~ /^ \*/;

    warn "Unknown entry '$lines[0]' at $ARGV:$.\n";
  }
}

&main
