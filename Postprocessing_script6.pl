#!/usr/bin/perl -i
use strict;
use warnings;

# Always helpful
use Math::Round;
use POSIX qw[ceil floor];
use List::Util qw[min max];
use constant PI    => 4 * atan2(1, 1);

##########
# SETUP
# all you can do here is setting default values for printing parameters
# since you don't have to do much here, just scroll down to PROCESSING
##########

# printing parameters
my %parameters=();

# printing parameters, default values (if needed)
$parameters{"someParameter"}=0.2;

# gcode inputBuffer
my @inputBuffer=();
my @outputBuffer=();
my @array=();
my $l = 0;			#counter for @array
my @moves=();
my $file;

# state variables, keeping track of what we're doing
my $start=0; # is set to 1 after ; start of print
my $end=0; # is set to 1 before ; end of print

##########
# INITIALIZE
# if you want to initialize variables based on printing parameters, do it here, all printing parameters are available in $parameters
##########

sub init{
	#for(my $i=0;$i<$parameters{"extruders"};$i++){
	#}
}

##########
# PROCESSING
# here you can define what you want to do with your G-Code
# Typically, you have $X, $Y, $Z, $E and $F (numeric values) and $thisLine (plain G-Code) available.
# If you activate "verbose G-Code" in Slic3r's output options, you'll also get the verbose comment in $verbose.
##########

sub process_start_gcode
{
	my $thisLine=$_[0];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub	process_end_gcode
{
	my $thisLine=$_[0];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub process_tool_change
{
	my $thisLine=$_[0],	my $T=$_[1], my $verbose=$_[2];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub process_comment
{
	my $thisLine=$_[0], my $C=$_[1], my $verbose=$_[2];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub process_layer_change
{
	my $thisLine=$_[0],	my $Z=$_[1], my $verbose=$_[2];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub process_retraction_move
{
	my $thisLine=$_[0], my $E=$_[1], my $F=$_[2], my $verbose=$_[3];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub process_printing_move
{
    #my $thisLine=$_[0], my $X = $_[1], my $Y = $_[2], my $Z = $_[3], my $E = $_[4], my $F = $_[5], my $verbose=$_[6];
	# add code here or just return $thisLine;
    #return $thisLine;
    my ($tmp1, $tmp2) = @_;
    my @lines = @{ $tmp1 };
    my @coords = @{ $tmp2 };
    my $count = $#coords;
    
    my @forward = ();  #define default for first point containing G X Y Z E
    my @previous = ();
    my @current = ();
    my @destination = ();
    
    for(my $i=0; $i<=$count; $i++){
        
        if($i < $count-1){
            $current[$i] = $coords[$i];
            $destination[$i] = $coords[$i+1];
            $forward[$i] = $coords[$i+2];
            if($i == 0){
                $previous[$i] = $coords[$count];
            }else{
                $previous[$i] = $coords[$i-1];
            }
        }elsif($i = $count-1){
            $current[$i] = $coords[$i];
            $destination[$i] = $coords[0];
            $forward[$i] = $coords[1];
            $previous[$i] = $coords[$i-1];
        }else{
            $current[$i] = $coords[$i];
            $destination[$i] = $coords[1];
            $forward[$i] = $coords[2];
            $previous[$i] = $coords[$i-1];
        }
        
		
        my $ax = $destination[$i][1] - $current[$i][1];
        my $ay = $destination[$i][2] - $current[$i][2];
        my $bx = $previous[$i][1] - $current[$i][1];
        my $by = $previous[$i][2] - $current[$i][2];
        my $cx = $forward[$i][2] - $destination[$i][2];
        my $cy = $forward[$i][2] - $destination[$i][2];
        
        
        if($current[$i][0] =~ /perimeter/){
            my $p_count = $parameters{"perimeters"};
            
            my $p_width = ($parameters{"external_perimeter_extrusion_width"})/2 + ($parameters{"perimeter_extrusion_width"})*($p_count - 1)/2; #will work for 2 perimeters only, generalize using if loop
            
            if(($p_width-$i*20)/20 >= 1){
                #Excel VBA
                
                my $theta_current = atan2($ax*$by - $ay*$bx, $ax*$bx + $ay*$by);
                my $gamma_current = atan2($bx, $by);
                my $theta_destination = atan2($cx*$ay - $cy*$ax, $cx*$ax + $cy*$ay);
                my $gamma_destination = atan2($ax, $ay);
            
                
                
                if(($destination[$i][2] < $current[$i][2]) and ($destination[$i][1] <= $current[$i][1])){
                    $theta_current += 2*PI;
                    $gamma_current = $gamma_current - 2*PI;
                }
                
                if(($forward[$i][2] < $destination[$i][2]) and ($forward[$i][1] <= $destination[$i][1])){
                    $theta_destination += 2*PI;
                    $gamma_destination = $gamma_destination - 2*PI;
                }
                
                my $current_threeX = $current[$i][1] + (20*(1+cos($theta_current))/sin($theta_current))*sin(PI/2) - ($theta_current + $gamma_current);
                my $current_threeY = $current[$i][2] + (20*(1+cos($theta_current))/sin($theta_current))*cos(PI/2) - ($theta_current + $gamma_current);
                
                my $current_fourX = $current[$i][1] + (20*(1+cos($theta_current))/sin($theta_current))*cos($gamma_current);
                my $current_fourY = $current[$i][1] + (20*(1+cos($theta_current))/sin($theta_current))*sin($gamma_current);
                
                my $destination_fourX = $destination[$i][1] + (20*(1+cos($theta_destination))/sin($theta_destination))*cos($gamma_destination);
                my $destination_fourY = $destination[$i][1] + (20*(1+cos($theta_destination))/sin($theta_destination))*sin($gamma_destination);
                
                
				#counter 2 if-else loop for E2/rotation axis
                my $e2;
                if($i == 2){
					$e2 = (PI/2 - ($theta_current + $gamma_current))*180/PI;
				}else{
					$e2 = ($theta_current - PI)*180/PI;
				}
				
                
                my $a13 = sqrt(($current_threeX - $current[$i][1])^2 + ($current_threeY - $current[$i][2])^2);
                my $a41 = sqrt(($current[$i][1] - $current_fourX)^2 + ($current[$i][2] - $current_fourY)^2);
                my $a34 = sqrt(($current_threeX - $destination_fourX)^2 + ($current_threeY - $destination_fourX)^2);
                my $a31 = sqrt(($current_threeX - $destination[$i][1])^2 + ($current_threeY - $destination[$i][2])^2);
                my $a14 = sqrt(($current[$i][1] - $destination_fourX)^2 + ($current[$i][2] - $destination_fourY)^2);
                my $a11 = sqrt(($current[$i][1] - $destination[$i][1])^2 + ($current[$i][2] - $destination[$i][2])^2);
                my $acd = sqrt(($destination[$i][1] - $current[$i][1])^2 + ($destination[$i][2] - $current[$i][1])^2);
                my $apc = sqrt(($current[$i][1] - $previous[$i][1])^2 + ($current[$i][2] - $previous[$i][2])^2);

                
                my $ecd = 0.0;
                if(($destination[$i][4] - $current[$i][4]) < 0){
                    $ecd = 0.0;
                }else{
                    $ecd = ($destination[$i][4] - $current[$i][4]);
                }
                
                
                my $epc = 0.0;
                
                if(($current[$i][4] - $previous[$i][4]) < 0){
                    $epc = 0.0;
                }else{
                    $epc = ($current[$i][4] - $previous[$i][4]);
                }
                
                
                my $e41 = ($epc*$a41)/$apc;
                my $e13 = ($ecd*$a13)/$acd;
                
                my $e34;
                
                if($theta_current<PI and $theta_destination<PI){
                    $e34 = ($ecd*$a34)/$acd;
                }elsif($theta_current<PI and $theta_destination>PI){
                    $e34 = ($ecd*$a31)/$acd;
                }elsif($theta_current>PI and $theta_destination<PI){
                    $e34 = ($ecd*$a14)/$acd;
                }elsif($theta_current>PI and $theta_destination>PI){
                    $e34 = ($ecd*$a11)/$acd;
                }
                
            
                if(abs($theta_current < PI)){
                    #current[i][4]
                    #E2
                    #no E
                    #E0
                    #@current[i][4] = $e41;
                    #return @current[i];
					if($current[$i][5]){
						print $file "\nG1 X".$current[$i][1]." Y".$current[$i][2]." Z".$current[$i][3]." Z".$current[$i][3]." A".$e41." F".$current[$i][5]."\n";
						print $file "\nG1 C".$e2."\n";
						print $file "\nG1 X".$current[$i][1]." Y".$current[$i][2]." Z".$current[$i][3]."\n";
						print $file "\nG1 X".$current_threeX." Y".$current_threeY." A".$e13." F".$current[$i][5]."\n";
					}else{
						print $file "\nG1 X".$current[$i][1]." Y".$current[$i][2]." Z".$current[$i][3]." Z".$current[$i][3]." A".$e41."\n";
						print $file "\nG1 C".$e2."\n";
						print $file "\nG1 X".$current[$i][1]." Y".$current[$i][2]." Z".$current[$i][3]."\n";
						print $file "\nG1 X".$current_threeX." Y".$current_threeY." A".$e13."\n";
					}	
                }else{
                    if($current[$i][5]){
						print $file "\nG1 X".$current[$i][1]." Y".$current[$i][2]." Z".$current[$i][3]." Z".$current[$i][3]." B".$e41." F".$current[$i][5]."\n";
						print $file "\nG1 C".$e2."\n";
						print $file "\nG1 X".$current[$i][1]." Y".$current[$i][2]." Z".$current[$i][3]."\n";
						print $file "\nG1 X".$current_threeX." Y".$current_threeY." B".$e13." F".$current[$i][5]."\n";
					}else{
						print $file "\nG1 X".$current[$i][1]." Y".$current[$i][2]." Z".$current[$i][3]." Z".$current[$i][3]." B".$e41."\n";
						print $file "\nG1 C".$e2."\n";
						print $file "\nG1 X".$current[$i][1]." Y".$current[$i][2]." Z".$current[$i][3]."\n";
						print $file "\nG1 X".$current_threeX." Y".$current_threeY." B".$e13."\n";
					}
                    
                }
				
				if(abs($theta_destination < PI)){
					if($current[$i][5]){
						print $file "\nG1 X".$destination_fourX." Y".$destination_fourY." A".$e34." B".$e34." F".$destination[$i][5]."\n";
					}else{
						print $file "\nG1 X".$destination_fourX." Y".$destination_fourY." A".$e34." B".$e34."\n";
					}
				}else{
					if($current[$i][5]){
						print $file "\nG1 X".$destination[$i][1]." Y".$destination[$i][2]." A".$e34." B".$e34." F".$destination[$i][5]."\n";
					}else{
						print $file "\nG1 X".$destination[$i][1]." Y".$destination[$i][2]." A".$e34." B".$e34."\n";
					}
				}
				
            }else{
                
                return @lines;
                
            }
            #Perimeter
         
        }elsif($current[$i][0] eq "skirt"){
            
            #skirt
             return @lines;
			
        }else{
            
            #Infill
             return @lines;
            
        }
        

    }
    
}

sub process_travel_move
{
	my $thisLine=$_[0], my $X=$_[1], my $Y=$_[2], my $Z=$_[3], my $F=$_[4], my $verbose=$_[5];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub process_touch_off
{
    my $thisLine=$_[0], my $X=$_[1], my $Y=$_[2], my $Z=$_[3], my $E=$_[4], my $verbose=$_[5];
    # add code here or just return $thisLine;
    return $thisLine;
}

sub process_absolute_extrusion
{
	my $thisLine=$_[0], my $verbose=$_[1];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub process_relative_extrusion
{
	my $thisLine=$_[0], my $verbose=$_[1];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub process_other
{
	my $thisLine=$_[0], my $verbose=$_[1];
	# add code here or just return $thisLine;
	return $thisLine;
}

##########
# FILTER THE G-CODE
# here the G-code is filtered and the processing routines are called
##########

sub filter_print_gcode
{
	my $thisLine=$_[0];
	if($thisLine=~/^\h*;(.*)\h*/){
		# ;: lines that only contain comments
		my $C=$1; # the comment
		return process_comment($thisLine,$C);
	}elsif ($thisLine=~/^T(\d)(\h*;\h*([\h\w_-]*)\h*)?/){
		# T: tool changes
		my $T=$1; # the tool number
		return process_tool_change($thisLine,$T);
	}elsif($thisLine=~/^G[01](\h+X(-?\d*\.?\d+))?(\h+Y(-?\d*\.?\d+))?(\h+Z(-?\d*\.?\d+))?(\h+E(-?\d*\.?\d+))?(\h+F(\d*\.?\d+))?(\h*;\h*([\h\w_-]*)\h*)?/){
		# G0 and G1 moves
		my $X=$2, my $Y=$4,	my $Z=$6, my $E=$8,	my $F=$10, my $verbose=$12;
		# regular moves and z-moves
        if(($l <= 1) || ($verbose eq $array[$l-1][0])){
            if($E){
                # seen E
                if($X || $Y || $Z){
                    # seen X,Y or Z
    
                    $moves[$l] = $thisLine;
                    my @tmp = ($verbose, $X, $Y, $Z, $E, $F);
                    $array[$l] = [@tmp];
                    $l++;
                    return;
                    #return process_printing_move($thisLine, $X, $Y, $Z, $E, $F, $verbose);
                }else{
                    # seen E, but not X, Y or Z
                    return process_retraction_move($thisLine, $E, $F, $verbose);
                }
            }else{
                # not seen E
                if($Z && !($X || $Y)){
                    # seen Z, but not X or Y
                    return process_layer_change($thisLine, $Z, $F, $verbose);
                }else{
                    # seen X or Y (and possibly also Z)
                    my $string = "move to first";
                    if($verbose =~ /\Q$string\E/){
                        @array = ();
                        @moves = ();
                        my @tmp = ($verbose, $X, $Y, $Z, 0, $F);
                        $array[0] = [@tmp];
                        $moves[0] = $thisLine;
                        $l++;
                        return;
                    }else{
                        return process_travel_move($thisLine, $X, $Y, $Z, $F, $verbose);
                    }
                }
            }
        }else{
            if($array[$l-1][0] =~ m/perimeter/){
                my @tmp1 = @array;
                my @tmp2 = @moves;
                @array = ();
                @moves = ();
                $l = 0;
                my $string = "move to first";
                if($verbose =~ /\Q$string\E/){
                    my @tmp = ($verbose, $X, $Y, $Z, 0, $F);
                    $array[$l] = [@tmp];
                    $moves[$l] = $thisLine;
                    $l++;
                    return process_printing_move(\@tmp2, \@tmp1);
                }elsif($verbose =~ m/inwards/){
                    push(@tmp2, $thisLine);
                    return process_printing_move(\@tmp2, \@tmp1);
                }
            
            }
        }
	}elsif($thisLine=~/^G92(\h+X(-?\d*\.?\d+))?(\h*Y(-?\d*\.?\d+))?(\h+Z(-?\d*\.?\d+))?(\h+E(-?\d*\.?\d+))?(\h*;\h*([\h\w_-]*)\h*)?/){
		# G92: touching of axis
		my $X=$2,	my $Y=$4, my $Z=$6, my $E=$8, my $verbose=$10;
		return process_touch_off($thisLine, $X, $Y, $Z, $E, $verbose);
	}elsif($thisLine=~/^M82(\h*;\h*([\h\w_-]*)\h*)?/){
		my $verbose=$2;
		return process_absolute_extrusion($thisLine, $verbose);
	}elsif($thisLine=~/^M83(\h*;\h*([\h\w_-]*)\h*)?/){
		my $verbose=$2;
		return process_relative_extrusion($thisLine, $verbose);
	}elsif($thisLine=~/^; end of print/){
		$end=1;
	}else{
		my $verbose;
		if($thisLine=~/.*(\h*;\h*([\h\w_-]*)\h*)?/){
			$verbose=$2;
		}
		# all the other gcodes, such as temperature changes, fan on/off, acceleration
		return process_other($thisLine, $verbose);
	}
}

sub filter_parameters
{
	# collecting parameters from G-code comments
	if($_[0] =~ /^\h*;\h*([\w_-]*)\h*=\h*(\d*\.?\d+)\h*/){
		# all numeric variables are saved as such
		my $key=$1;
		my $value = $2*1.0;
		unless($value==0 && exists $parameters{$key}){
			$parameters{$key}=$value;
		}
	}elsif($_[0] =~ /^\h*;\h*([\h\w_-]*)\h*=\h*(.*)\h*/){
		# all other variables (alphanumeric, arrays, etc) are saved as strings
		my $key=$1;
		my $value = $2;
		$parameters{$key}=$value;
	}
}


sub print_parameters
{
	# this prints out all available parameters into the G-Code as comments
	print $file "; GCODE POST-PROCESSING PARAMETERS:\n\n";
	print $file "; OS: $^O\n\n";
	print $file "; Environment Variables:\n";
	foreach (sort keys %ENV) {
		print $file "; $_  =  $ENV{$_}\n";
	}
	print $file "\n";
	print $file "; Slic3r Script Variables:\n";
	foreach (sort keys %parameters) {
		print $file "; *$_*  =  $parameters{$_}\n";
	}
	print $file "\n";
}

sub process_buffer
{
	# applying all modifications to the G-Code
	foreach my $thisLine (@inputBuffer) {

		# start/end conditions
		if($thisLine=~/^; start of print/){
			$start=1;
		}elsif($thisLine=~/^; end of print/){
			$end=1;
		}

		# processing
		if($start==0){
			push(@outputBuffer,process_start_gcode($thisLine));
		}elsif($end==1){
			push(@outputBuffer,process_end_gcode($thisLine));
		}else{
			push(@outputBuffer,filter_print_gcode($thisLine));
		}
	}
}

sub print_buffer
{
    #open my $file, '>', 'Sample.gcode' or die $!;
	
	foreach my $outputLine (@outputBuffer) {
		print $file $outputLine;
	}
	
    #close $file;
}

##########
# MAIN LOOP
##########

# Creating a backup file for windows
if($^O=~/^MSWin/){
	$^I = '.bak';
}

while (my $thisLine=<>) {
	filter_parameters($thisLine);
	push(@inputBuffer,$thisLine);
	if(eof){
		open($file, '>', 'Sample.gcode') or die $!;
            process_buffer();
            init();
            print_parameters();
            print_buffer();
        close $file;
	}
}
