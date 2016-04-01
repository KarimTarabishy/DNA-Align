# DNA-Align
Global, semi-global and local alignment for dna sequences

# USAGE
In `alignment.pl` script there exist a configuration where you can configure scores, and define the files where pairs of dna sequences exists in.

Each file should contain only 2 sequences separated by a newline. 
```perl
  my %scores = ('int_gap' => -5, 'term_gap' => 0, 'match' => 5, 'miss' => -4);
  my @files = ("seq/Sequence_Pair_1.txt","seq/Sequence_Pair_2.txt","seq/Sequence_Pair_3.txt");
```


In cosole type `perl alignment.pl` and an output file will be created with results.

#Sample

seq/Sequence_Pair_1.txt file:
```
TGGTAGATTCCCACGAGATCTACCGAGTATGAGTAGGGGGACGTTCGCTCGG
GCCTCTAACACACTGCACGAGATCAACCGAGATATGAGTAATACAGCGGTACGGG
```

output

```
seq/Sequence_Pair_1.txt:


##########################
###  global alignment  ###
##########################

---TGGTAGATTC-C--CACGAGATCTACCGAG-TATGAGTAGGGGGAC-GTTCGCT-C-GG
   | .|| |..| |  |||||||||.|||||| ||||||||   ..|| |  ||.| | ||
GCCT-CTA-ACACACTGCACGAGATCAACCGAGATATGAGTA---ATACAG--CGGTACGGG

		14 gaps, 38 matches, 7 misses.
		score: 77 



#########################
###  local alignment  ###
#########################

                ************************* 
    TGGTAGATTCC CACGAGATCTACCGAG-TATGAGTA GGGGGACGTTCGCTCGG
                |||||||||.|||||| |||||||| 
GCCTCTAACACACTG CACGAGATCAACCGAGATATGAGTA ATACAGCGGTACGGG
                ************************* 

		1 gaps, 23 matches, 1 misses.
		score: 106 



###############################
###  semi-global alignment  ###
###############################

---TGGTAGATTC-C--CACGAGATCTACCGAG-TATGAGTAGGGGGAC-GTTCGCT-CGG-
   | .|| |..| |  |||||||||.|||||| ||||||||   ..|| |  ||.| ||| 
GCCT-CTA-ACACACTGCACGAGATCAACCGAGATATGAGTA---ATACAG--CGGTACGGG

		13 internal gaps, 4 terminal gaps, 38 matches, 7 misses.
		score: 97 


```
