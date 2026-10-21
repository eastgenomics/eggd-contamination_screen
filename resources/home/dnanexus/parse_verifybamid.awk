#!/usr/bin/awk
## parse_verifybamid.awk

function reformat_freemix(val){
    val=round_to_five_dp(val)
    val=remove_trailing_zeroes(val)
    return(val)
}

function round_to_five_dp(val){
    val=sprintf("%.5f", val / 100)
    return(val)
}

function remove_trailing_zeroes(val){
    sub(/0+$/, "", val);
    sub(/\.$/, ".0", val);
    return(val)
}

BEGIN {
    FS=OFS="\t";
    print "Sample\tFREEMIX";
}
NR > 1 { 
    freemix=reformat_freemix($6)
    print $1, freemix
}
