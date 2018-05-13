#!/usr/bin/env perl

#use Shell::Source;

#$env_path= Shell::Source->new(shell=>"tcsh",file=>"/uge/ncd/current/misl_ncd/common/settings.csh");
#$env_path->inherit;

open(SRVUSAGE, "qhost -F -q -l m_mem_total=1g | egrep -wi '^lnx[0-9]*|mem_free|cpu|heavy|bulk'|") or die $!; 
@srvusage = <SRVUSAGE>;
close SRVUSAGE;

$hostc = 0; $total_cpuusage = 0; $total_memusage = 0; $total_memusagereq=0 ;$total_cpunumber = 0; $total_memsize = 0; $total_heavy_used=0; $total_heavy_total=0; $total_bulk_used=0; $total_bulk_total=0; $totalhostnames="";
foreach $usage ( @srvusage ) {
 if ($usage =~ /\s*-\n$/) { next; }     # don't calculate unavail hosts

  if ( $usage =~ /lnx/ || $usage =~ /Lnx/ ) {
    @host_load = split (" " , $usage);
    $hostname = $host_load[0];
    $cpunumber = $host_load[4];
    $totalmem = $host_load[7];
    $savetotalmem = $host_load[7];
    $memused = $host_load[8];
    $hostc++;
    $totalhostnames .= "$hostname ";

    if ( $totalmem =~ /G/ && $memused =~ /G/ ) {
     chop $totalmem;
     chop $memused;
     $memusage = int( $memused / $totalmem * 100);
    }
    elsif ( $totalmem =~ /G/ && $memused =~ /M/ ) {
     chop $totalmem;
     chop $memused;
     $totalmemM= $totalmem * 1024;
     $memusage = int( $memused / $totalmemM * 100);
    }
    else {
     chop $totalmem;
     chop $memused;
     $totalmemK= $totalmem * 1024 * 1024;
     $memusage = int( $memused / $totalmemK * 100);
    }
    $total_memusage+=$memusage;
    $total_cpunumber+=$cpunumber;
    $total_memsize+=$totalmem;
    $hostname_array{$hostname}{'cores'}=$cpunumber;
    $hostname_array{$hostname}{'mem'}=$totalmem;
    $hostname_array{$hostname}{'memusage'}=$memusage;
    $hostname_array{$hostname}{'count'}++;
  }

 elsif ( $usage =~ /mem_free/ ) {
    @mem_array = split("=", $usage);
    $mem_free= $mem_array[1];

    if ( $savetotalmem =~ /G/ && $mem_free =~ /G/ ) {
     chop $savetotalmem;
     chop $mem_free;
     $used_mem = int ( $savetotalmem - $mem_free );
     $memusage = int ( $used_mem / $savetotalmem * 100);
    }
    elsif ( $savetotalmem =~ /G/ && $mem_free =~ /M/ ) {
     chop $savetotalmem;
     chop $mem_free;
     $totalmemM = $savetotalmem * 1024;
     $used_mem = int ( $totalmemM - $mem_free );
     $memusage = int ( $used_mem / $totalmemM * 100);
    }
    else {
     chop $totalmem;
     chop $mem_free;
     $totalmemK = $savetotalmem * 1024 * 1024;
     $used_mem = int ( $totalmemK - $mem_free );
     $memusage = int ( $used_mem / $totalmemK * 100);
    }
     $hostname_array{$hostname}{'memusagereq'}=$memusage;
     $total_memusagereq+=$memusage;
 }

 elsif ( $usage =~ /cpu/ ) {
    @cpu_array = split("=", $usage);
    $cpuload = $cpu_array[1];
    $total_cpuusage+=$cpuload;
    $cpuload =~ s/\n$//;
    $hostname_array{$hostname}{'cpu'}=$cpuload;
 }
 elsif ( $usage =~ /heavy/ ) {
    @queue_data = split(' ', $usage);
    if ( defined($queue_data[3]) ) {
      $queue_state=$queue_data[3];
      if ( $queue_state =~ /u/ ) {next;}
      elsif ( $queue_state =~ /d/ || $queue_state =~ /D/ || $queue_state =~ /E/ || $queue_state =~ /a/ ) {
       $slots = $queue_data[2];
       @split_slots = split('/', $slots);
       if ( $split_slots[1] > 0 ) {
          $hostname_array{$hostname}{'heavy_used'}=$split_slots[1];
          $hostname_array{$hostname}{'heavy_total'}=$split_slots[1];
          $total_heavy_used+=$split_slots[1];
          $total_heavy_total+=$split_slots[1];
       }
      }
    }
   else {
       $slots = $queue_data[2];
       @split_slots = split('/', $slots);
       $hostname_array{$hostname}{'heavy_used'}=$split_slots[1];
       $hostname_array{$hostname}{'heavy_total'}=$split_slots[2];
       $total_heavy_used+=$split_slots[1];
       $total_heavy_total+=$split_slots[2];
   }
 }
 elsif ( $usage =~ /bulk/ ) {
    @queue_data = split(' ', $usage);
    if ( defined($queue_data[3]) ) {
      $queue_state=$queue_data[3];
      if ( $queue_state =~ /u/ ) {next;}
      elsif ( $queue_state =~ /d/ || $queue_state =~ /D/ || $queue_state =~ /E/ || $queue_state =~ /a/ ) {
       $slots = $queue_data[2];
       @split_slots = split('/', $slots);
       if ( $split_slots[1] > 0 ) {
          $hostname_array{$hostname}{'bulk_used'}=$split_slots[1];
          $hostname_array{$hostname}{'bulk_total'}=$split_slots[1];
          $total_bulk_used+=$split_slots[1];
          $total_bulk_total+=$split_slots[1];
       }
      }
    }
   else {
       $slots = $queue_data[2];
       @split_slots = split('/', $slots);
       $hostname_array{$hostname}{'bulk_used'}=$split_slots[1];
       $hostname_array{$hostname}{'bulk_total'}=$split_slots[2];
       $total_bulk_used+=$split_slots[1];
       $total_bulk_total+=$split_slots[2];
   }
 }
}

$HEAVYFILE="/uge/ncd/8.1.7/misl_ncd/spool/qmaster/cqueues/heavy";
$LAYOUTFILE="/uge/ncd/8.1.7/misl_ncd/spool/qmaster/cqueues/layout";

open(HEAVY, "$HEAVYFILE") or die $!;
@heavy = <HEAVY>;
close HEAVY;

$allhosts=""; $allgroups="";
foreach $line (@heavy) { 
 if ( $line =~ /$user_lists\sNONE,/ ) {
   $line =~ s/\[|\]/ /g;
   @allocated_hosts=split("," , $line );
   shift @allocated_hosts; 
   foreach $host ( @allocated_hosts ) {
     @hostandgroup = split("=" , $host);
     $hostfqn=$hostandgroup[0];
     $group=$hostandgroup[1];
     $group =~ s/\n$//;
     @hostnamefqn = split(/\./ , $hostfqn);
     $hostname=$hostnamefqn[0];
     $hostname_array{$hostname}{'group'}=$group;
     $allhosts .= $hostname; 
     $allgroups .= $group;
   }
 }
}



open(LAYOUT, "$LAYOUTFILE") or die $!;
@layout = <LAYOUT>;
close LAYOUT;

foreach $line (@layout) {
 if ( $line =~ /$user_lists\slayout_users/ ) {
   $line =~ s/\[|\]/ /g;
   @allocated_hosts=split("," , $line );
   shift @allocated_hosts;
   shift @allocated_hosts;
   foreach $host ( @allocated_hosts ) {
     @hostandgroup = split("=" , $host);
     $hostfqn=$hostandgroup[0];
     $group=$hostandgroup[1];
     $group =~ s/\n$//;
     @hostnamefqn = split(/\./ , $hostfqn);
     $hostname=$hostnamefqn[0];
     $hostname_array{$hostname}{'group'}=$group;
     $allhosts .= $hostname;
     $allgroups .= $group;
   }
 }
}

@hostsarray = split( " " , $allhosts);
@groupsarray = split( " " , $allgroups);


%hashTemp = map { $_ => 1 } @groupsarray;
@unique_groups = sort keys %hashTemp;


foreach $host ( @hostsarray ) {
  foreach $group ( @unique_groups ) {
    $grouphost=$hostname_array{" $host"}{'group'};
    $grouphost =~ s/\ //;
    if ( $group eq $grouphost ) {
     $array_2d{$group}{'cores'} += $hostname_array{$host}{'cores'};
     $array_2d{$group}{'cpu'} += $hostname_array{$host}{'cpu'};
     $array_2d{$group}{'mem'} += $hostname_array{$host}{'mem'};
     $array_2d{$group}{'memusage'} += $hostname_array{$host}{'memusage'};
     $array_2d{$group}{'memusagereq'} += $hostname_array{$host}{'memusagereq'};
     $array_2d{$group}{'count'} +=$hostname_array{$host}{'count'};
     $array_2d{$group}{'heavytot'} +=$hostname_array{$host}{'heavy_total'};
     $array_2d{$group}{'heavyuse'} +=$hostname_array{$host}{'heavy_used'};
     $array_2d{$group}{'bulktot'} +=$hostname_array{$host}{'bulk_total'};
     $array_2d{$group}{'bulkuse'} +=$hostname_array{$host}{'bulk_used'};
     break;
    }
  } 
     $array_all{'cores'} += $hostname_array{$host}{'cores'};
     $array_all{'cpu'} += $hostname_array{$host}{'cpu'};
     $array_all{'mem'} += $hostname_array{$host}{'mem'};
     $array_all{'memusage'} += $hostname_array{$host}{'memusage'};
     $array_all{'memusagereq'} += $hostname_array{$host}{'memusagereq'};
     $array_all{'count'} +=$hostname_array{$host}{'count'};
     $array_all{'heavytot'} +=$hostname_array{$host}{'heavy_total'};
     $array_all{'heavyuse'} +=$hostname_array{$host}{'heavy_used'};
     $array_all{'bulktot'} +=$hostname_array{$host}{'bulk_total'};
     $array_all{'bulkuse'} +=$hostname_array{$host}{'bulk_used'};
}


# Calculate non reserved hosts
@reserved_hosts = split ( " " , $allhosts);
@total_hosts = split ( " " , $totalhostnames);
map {$result=$_ ; grep { /$result/ } @reserved_hosts or push @results, $result; } @total_hosts;


foreach $host ( @results ) {
     $array_nonres{'cores'} += $hostname_array{$host}{'cores'};
     $array_nonres{'cpu'} += $hostname_array{$host}{'cpu'};
     $array_nonres{'mem'} += $hostname_array{$host}{'mem'};
     $array_nonres{'memusage'} += $hostname_array{$host}{'memusage'};
     $array_nonres{'memusagereq'} += $hostname_array{$host}{'memusagereq'};
     $array_nonres{'count'} +=$hostname_array{$host}{'count'};
     $array_nonres{'heavytot'} +=$hostname_array{$host}{'heavy_total'};
     $array_nonres{'heavyuse'} +=$hostname_array{$host}{'heavy_used'};
     $array_nonres{'bulktot'} +=$hostname_array{$host}{'bulk_total'};
     $array_nonres{'bulkuse'} +=$hostname_array{$host}{'bulk_used'};
}




printf ("\n\n%s\n" , "Group Name:(# of server(s))  CPU util    MEM util     MEM req.   CPU #   MEM size(GB)   Heavy slots(used/total)   Bulk slots(used/total)");
foreach $group ( @unique_groups ) {
  if ( $array_2d{$group}{'count'} > 0 ) {
  $avg_cpu = int ( $array_2d{$group}{'cpu'} / $array_2d{$group}{'count'} );
  $avg_memusage = int ( $array_2d{$group}{'memusage'} / $array_2d{$group}{'count'} );
  $avg_memusagereq = int ( $array_2d{$group}{'memusagereq'} / $array_2d{$group}{'count'} );
  printf("%-29s  %-11s  %-10s  %-10s %-10d %-20d %3d/%-18d  %3d/%d\n" , "$group($array_2d{$group}{'count'})" , "$avg_cpu%" , "$avg_memusage%" , "$avg_memusagereq%" , $array_2d{$group}{'cores'} , $array_2d{$group}{'mem'} , $array_2d{$group}{'heavyuse'} , $array_2d{$group}{'heavytot'} , $array_2d{$group}{'bulkuse'} , $array_2d{$group}{'bulktot'}) ; 
  }
}

if ( $array_all{'count'} > 0 ) {
  $avg_cpu = int ( $array_all{'cpu'} / $array_all{'count'} );
  $avg_memusage = int ( $array_all{'memusage'} / $array_all{'count'} );
  $avg_memusagereq = int ( $array_all{'memusagereq'} / $array_all{'count'} );
  printf("\n%-29s  %-11s  %-10s  %-10s %-10d %-20d %3d/%-18d  %3d/%d\n" , "All_Reserved($array_all{'count'})" , "$avg_cpu%" , "$avg_memusage%" , "$avg_memusagereq%" , $array_all{'cores'} , $array_all{'mem'} , $array_all{'heavyuse'} , $array_all{'heavytot'} , $array_all{'bulkuse'} , $array_all{'bulktot'}) ;
}


if ( $array_nonres{'count'} > 0 ) {
  $avg_cpu = int ( $array_nonres{'cpu'} / $array_nonres{'count'} );
  $avg_memusage = int ( $array_nonres{'memusage'} / $array_nonres{'count'} );
  $avg_memusagereq = int ( $array_nonres{'memusagereq'} / $array_nonres{'count'} );
  printf("\n%-29s  %-11s  %-10s  %-10s %-10d %-20d %3d/%-17d  %3d/%d\n" , "None_Reserved($array_nonres{'count'})" , "$avg_cpu%" , "$avg_memusage%" , "$avg_memusagereq%" , $array_nonres{'cores'} , $array_nonres{'mem'} , $array_nonres{'heavyuse'} , $array_nonres{'heavytot'} , $array_nonres{'bulkuse'} , $array_nonres{'bulktot'}) ;
}


$avg_cpu_usage = int ( $total_cpuusage / $hostc );
$avg_mem_usage = int ( $total_memusage / $hostc );
$avg_memreq_usage = int ( $total_memusagereq / $hostc );


printf("\n\n%-22s %-20s %-11s %-10s %-10s %-20d %3d/%-17d  %3d/%d\n" , "TOTAL Cluster($hostc)=" , "        $avg_cpu_usage%" , "$avg_mem_usage%" , "$avg_memreq_usage%" , "$total_cpunumber" , "$total_memsize" , $total_heavy_used , $total_heavy_total , $total_bulk_used , $total_bulk_total);
