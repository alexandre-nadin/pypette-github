import os
import sys
print(os.path.abspath(os.path.curdir + os.sep + "ctgbpipe" + os.sep + "python-lib"))
sys.path.insert(0, os.path.abspath(os.path.curdir + os.sep + "ctgbpipe" + os.sep + "python-lib"))
import fastq_helper as fh
import csv_helper as csvh
include: "config.sk"

#RUN_BASEDIR = "/lustre2/scratch/anadin/pipeline-snakemake"
RUN_BASEDIR = "/lustre2/raw_data"
#RAW_DATA_DIRS = [ RUN_BASEDIR + "/run1", RUN_BASEDIR + "/run2" ]
RAW_DATA_DIRS = [ RUN_BASEDIR + "/" + _runid for _runid in RUN_IDS ]
RUN_IDS = [ os.path.basename(runpath) for runpath in RAW_DATA_DIRS ]
cmap = csvh.CsvMap('fastq_samples.map', delimitor='\t', colnames=fh.FastqFile.get_field_names()) 
fastq_map_sep = "\t"
fastq_samples_map = "fastq_samples.map"

localrules: pbs_dir
rule pbs_dir:
    output:
        primary= {PBS_DIR}
    shell:"""
      mkdir -p {PBS_DIR}
    """


# ---------------------
# Mapping fastq files
# ---------------------
rule setup:
    #
    # Sets up the folder.
    #
    input: "fastq_samples.map", PBS_DIR
    #output: primary= rule + ".done"
    #shell:"""
    #  touch {output}
    #"""

rule fastq_files:
    output: 
        primary= "fastq_files.txt"
    shell:"""
      find {RAW_DATA_DIRS} -name '*.fastq.gz' > {output}
    """

rule fastq_samples:
    #
    # Maps all the illumina filename metadata in a file.
    #
    input: 
        file="fastq_files.txt"
    output: 
        primary="fastq_samples.map"
    run:
        with open(input['file'], 'r') as files:
            for _file in files:
                ## Deduce file's run name
                sample_run = get_run_from_filepath(_file, RAW_DATA_DIRS)

                ## Get file's info
                fastqfile = fh.FastqFile(_file.strip(), run_name=sample_run)

                ## Write to output
                with open(output['primary'], 'a') as fmap:
                    fmap.write("{}{}".format(fastq_map_sep.join(
                      [fastqfile.__dict__[_field] \
                        for _field in list(fh.FastqFile.get_field_names())
                      ]
                     ), os.linesep))

struct_fastq_path="{sample_run}/{sample_name}/{sample_name}_{sample_number}_{sample_lane}_{sample_read}_{sample_chunknb}.fastq.gz"
struct_chunk=""
# -----------------
# Link fastq reads
# -----------------
def cmap__query_wildcards(cmap, wildcards):
    return cmap.query(**dict(wildcards.items()))

def cmap__fastq_chunks(cmap, wildcards, out_prefix='', out_suffix=''):
    return [
      out_prefix + _fastq_map[cmap.colindexes.sample_path] + out_suffix
              for _fastq_map in 
          cmap.query(**dict(wildcards.items()))
    ]

localrules: link_fastq_read
rule link_fastq_read:
    #
    # Links original fastq file to the project directory.
    #
    input:
        #samples_map = fastq_samples_map,
        fastq_read = lambda wildcards: cmap__fastq_chunks(cmap, wildcards)
    output: 
        primary="{sample_run}/{sample_name}/{sample_name}_{sample_number}_{sample_lane}_{sample_read}_{sample_chunknb}.fastq.gz"
    wildcard_constraints:
        sample_name=fh.FastqFile.fields_regex_dic['sample_name'],
        sample_number=fh.FastqFile.fields_regex_dic['sample_number'],
        sample_lane=fh.FastqFile.fields_regex_dic['sample_lane'],
        sample_read=fh.FastqFile.fields_regex_dic['sample_read'],
        sample_chunknb=fh.FastqFile.fields_regex_dic['sample_chunknb']
    shell:"""
      ln.rel {input[fastq_read]} {output[primary]} 
    """

# ---------------
# Fastq Quality
# ---------------
rule fastqc_file:
    input:
        fastq_in= "{prefix}.fastq.gz"
    output:
        primary= "{prefix}.fastqc.html"
    shell:"""
      fastqc -o $(dirname {input[fastq_in]}) -t {CORES} {input[fastq_in]}
    """ 


# -----------------
# Fastq Trimming
# -----------------
rule fasta_adapters:
    input: 
        adapter_fasta="/lustre1/genomes/Illumina_Adapters/Adapters.fasta"
        # SUGGESTION: set an ADAPTER_FASTA_PATH variable in config.sk (everything that has hardcoded paths actually)
    output:
        primary="adapters.fa"
    shell:"""
      condactivate
      ## Substitute uracil in timin; Remove empty lines.
      perl -pe 'if(!m/^>/){{ tr/U/T/}}' {input[adapter_fasta]} \
       | grep . > {output[primary]}.tmp1
      reverse_fasta < {output[primary]}.tmp1 \
       | perl -lpe 'if(m/^>/){{$_=$_."_reverse"}}' \
       > {output[primary]}.tmp2
      cat {output[primary]}.tmp1 {output[primary]}.tmp2 \
       > {output[primary]}
      rm {output[primary]}.tmp1 {output[primary]}.tmp2
    """

rule printparams:
    output:
        primary= "paramprinted"
    shell:"""
      sleep 5
      echo "done that"
    """
TRIMMED = '.cutadapt' #'.trimmomatic'
## TRIMMING with trimmomatic
# SUGGESTION: 
#  v Rename variable in TRIMMOMATIC_CMD -> clarity in variable names.
#  - Hardcoded paths go in config.sk file
#  - Make a single uniform rule for trimmomatic by managing the paired condition in the input.
TRIMMOMATIC_CMD="/lustre1/tools/libexec/Trimmomatic-0.32/trimmomatic-0.32.jar"
rule trimmomatic_fastq:
    input: 
        fastq_file = "{prefix}.fastq.gz",
        adapter = "adapters.fa"
    output: 
        primary = "{prefix}.trimmomatic.fastq.gz"
    shell:"""
      java -Djava.io.tmpdir=$TMPDIR -Xmx{TRIMMOMATIC_RAM_JAVA} \
        -jar {TRIMMOMATIC_CMD} {TRIMMOMATIC_PAIRED} \
        -phred33 \
        -trimlog {output[primary]}.log \
        {input[fastq_file]} \
        {output[primary]} \
        ILLUMINACLIP:{input[adapter]}:2:30:10 \
        LEADING:3 \
        TRAILING:3 \
        SLIDINGWINDOW:4:15 \
        MINLEN:15 \
        {TRIMMOMATIC_HEADCROP} \
        > {output[primary]}.out
      #touch {output} # DRY_RUN
    """

#ruleorder: trimmomatic_fastq > cutadapt_fastq > link_fastq_file   
## TRIMMING with cut_adapt 
CUTADAPT_B=" -b file:adapters.fa"  #CUT_ADAPTER
CUTADAPT_Q=" -q 30,30" #TRIM_Q
CUTADAPT_U=" -u 13" #TRIM_CUT
CUTADAPT_M=" -m 15" #TRIM_MIN_LEN  # Let always set to avoid read without sequence after trimming
rule cutadapt_fastq:
    input:
        fastq_file = "{prefix}.fastq.gz",
        adapter = "adapters.fa"
    output: 
        primary = "{prefix}.cutadapt.fastq.gz"
    shell:"""
      condactivate  # >  {output[primary]}.out # DRY_RUN
      cutadapt {CUTADAPT_B} \
        --trim-n {CUTADAPT_Q} \
        {CUTADAPT_U} \
        {CUTADAPT_M} \
        -o {output[primary]} \
        {input[fastq_file]} \
       > "{output[primary]}.log"
      #touch {output} # DRY_RUN
    """


# ----------------
# STAR alignment
# ----------------
# ALign Parameters
# snakemake -p RULE/FILE --use-conda # --cluster 'qsub' --jobs 9999 --latency-wait 10
#snakemake -p run2/36258535_id/36258535_id_S10_L5_001.bam --cluster-config cluster.yaml  --cluster 'qsub -N {cluster.name} -l select={cluster.select}:ncpus={cluster.cores}:mem={cluster.mem}' --jobs 9999  --latency-wait 10
STAR_VERSION = "STAR_2.5.3a"
STAR_RAM = "32gb"
CORES = 6
STAR_outFilterMismatchNmax = 10 
STAR_GENOME_INDEX = BIOINFO_ROOT + '/task/annotations/dataset/gencode/' \
     + SPECIES + '/' + GENCODE_VERSION + '/' + GENCODE_GENOME_VERSION \
     + '.primary_assembly.star_index/' + STAR_VERSION

## TOREMOVE
rule testvars:
    run:
        print("""[testing variables]
          RAW_DATA_DIRS: {}
          STAR_GENOME_INDEX: {}" 
          RMD_METADATA_HEATMAP: {}" 
          LIMMA_CONTRASTS: {}" 
          RMD_BIOTYPE_PNG: {}" 
        """.format(RAW_DATA_DIRS, STAR_GENOME_INDEX, RMD_METADATA_HEATMAP, LIMMA_CONTRASTS, RMD_BIOTYPE_PNG))
        shell("""
          ls {PRJ_ROOT}
        """)

def cmap__fastq_reads(cmap, wildcards, out_prefix='', out_suffix=''):
    #
    # Gets all the fastq chunknames from a Snakemake rule's wildcards. 
    #
    wc_dict = dict(wildcards.items())
    return set([ str(
                   out_prefix
                 + _fastq_map[cmap.colindexes.sample_chunkname] 
                 + out_suffix
                ).format(**wc_dict)
              for _fastq_map in cmap.query(**wc_dict)
    ])

out_chunk_bam_pattern="{sample_run}/{sample_name}/{sample_name}_{sample_number}_{sample_lane}_{sample_chunknb}{process}"
rule align_chunk_star:
    input:
        # samples_map = fastq_samples_map,
        fastq_reads = lambda wildcards: cmap__fastq_reads(
						cmap, 
                    				wildcards, 
 						out_prefix="{sample_run}/{sample_name}/", 
						out_suffix="{process}.fastq.gz")
    output: 
        primary = out_chunk_bam_pattern + ".bam",
        bam_file_raw = out_chunk_bam_pattern + ".Aligned.sortedByCoord.out.bam",
        raw_files = [ out_chunk_bam_pattern + "." + _raw for _raw in
             [ "Log.out", "Log.progress.out", "Log.final.out", "SJ.out.tab" ]
        ]

    wildcard_constraints:
        sample_name=fh.FastqFile.fields_regex_dic['sample_name'],
        sample_number=fh.FastqFile.fields_regex_dic['sample_number'],
        sample_lane=fh.FastqFile.fields_regex_dic['sample_lane'],
        sample_chunknb=fh.FastqFile.fields_regex_dic['sample_chunknb'],
        process="(\.\w+)*"
    shell:"""
       condactivate #> {output[primary]}.out ## DRY_RUN
       STAR \
         --runThreadN {CORES} \
         --genomeDir {STAR_GENOME_INDEX} \
         --readFilesIn {input[fastq_reads]} \
         --outSAMstrandField intronMotif \
         --outFileNamePrefix {wildcards.sample_run}/{wildcards.sample_name}/{wildcards.sample_name}_{wildcards.sample_number}_{wildcards.sample_lane}_{wildcards.sample_chunknb}{wildcards.process}. \
         --outSAMtype BAM SortedByCoordinate \
         --outSAMunmapped Within \
         --outFilterMismatchNmax {STAR_outFilterMismatchNmax} \
         --readFilesCommand zcat \
        > {output[primary]}.out;  # DRY_RUN
       #touch {output} ## DRY_RUN 
       ln.rel -f {output[bam_file_raw]} {output[primary]}
     """


# ------------
# Merge BAMs
# ------------
def cmap__bam_chunks(cmap, wildcards, out_prefix='', out_suffix=''):
    #
    # Gets all the fastq chunknames from a Snakemake rule's wildcards. 
    #
    wc_dict = dict(wildcards.items())
    return set([ str(
                   out_prefix
                 + _fastq_map[cmap.colindexes.sample_run] 
                 + os.sep + _fastq_map[cmap.colindexes.sample_name]
                 + os.sep + _fastq_map[cmap.colindexes.sample_name]
                 + '_' + _fastq_map[cmap.colindexes.sample_number]
                 + '_' + _fastq_map[cmap.colindexes.sample_lane]
                 + '_' + _fastq_map[cmap.colindexes.sample_chunknb]
                 + "{process}.bam"
                 + out_suffix
                ).format(**wc_dict)
              for _fastq_map in cmap.query(**wc_dict)
    ])


rule merge_sample_bam_chunks:
    input:
        bam= lambda wildcards: cmap__bam_chunks(cmap, wildcards)
    output:
        primary= "BAM/{sample_name}{process}.bam",
        bai= "BAM/{sample_name}{process}.bai"
    wildcard_constraints:
        sample_name=fh.FastqFile.fields_regex_dic['sample_name'],
        sample_number=fh.FastqFile.fields_regex_dic['sample_number'],
        sample_lane=fh.FastqFile.fields_regex_dic['sample_lane'],
        sample_chunknb=fh.FastqFile.fields_regex_dic['sample_chunknb'],
        process="(\.\w+)*"
    run:
        shell("""
          mkdir -p BAM  # > {o[primary]}.log # DRY_RUN
          if [[ `wc -w <<<"{i[bam]}"` -gt 1 ]]; then
            echo "[DOING if]"
            java -jar /lustre1/tools/bin/MergeSamFiles.jar {merge_prefixes} \
              O={o[primary]} \
              CREATE_INDEX=true \
              MSD=true \
              TMP_DIR=$TMPDIR \
              VALIDATION_STRINGENCY=SILENT \
             > {o[primary]}.log
          else
              link_install {i[bam]} {o[primary]} # >> {o[primary]}.log # DRY_RUN
              ORIG_BAI=$(sed 's/bam/bai/g' <<< {i[bam]})
              echo "[DOING else]"
              [ -e $ORIG_BAI ] \
                && link_install -f $ORIG_BAI $(sed 's/bam/bai/g' <<< {o[primary]}) \
                || echo WARNING bai file $ORIG_BAI not found \ 
                >&2 # >> {o[primary]}.log # DRY_RUN
          fi  
        """.format(i=input, o=output, merge_prefixes=" ".join([ "I=" + _prefix for _prefix in input.bam ])))


def cmap__bam_sample_chunks(cmap, wildcards, out_prefix='', out_suffix=''):
    #
    # Gets the path of all expected sample bams.
    #
    wc_dict = dict(wildcards.items())
    return set([ str(
                   out_prefix
                 + "BAM"
                 + os.sep + _fastq_map[cmap.colindexes.sample_name]
                 + "{process}.bam"
                 + out_suffix
                ).format(**wc_dict)
              for _fastq_map in cmap.query(**wc_dict)
    ])

rule merge_all_bam_chunks:
    input: 
        cmap= fastq_samples_map,
        bams= lambda wildcards: cmap__bam_sample_chunks(cmap, wildcards)
    output: 
        primary= "all_bam_chunks_merged{process}.done"
    wildcard_constraints:
        sample_name=fh.FastqFile.fields_regex_dic['sample_name'],
        process="(\.\w+)*"
    shell:"""
      touch {output}
    """


# ----------
# Cleaning
# ----------
rule cleanall:
    shell:"""
      #'rm -rf {RUN_IDS} *.done;' #fastq_samples.map fastq_files.txt;'
      rm -rf {RUN_IDS} \
       *.done *_done \
       fastq_samples.map \
       fastq_files.txt \
       *.{{e,o}}* \
       BAM/ \
       *.fa
     """

# -------------
# PERFORMANCES
# -------------
## Dataset:
# $ du -hs /lustre2/raw_data/160801_SN859_0318_BHLYGFBCXX/Project_Gabellini_304_Custom_RNAseq/        
# 6.3G    /lustre2/raw_data/160801_SN859_0318_BHLYGFBCXX/Project_Gabellini_304_Custom_RNAseq/

## Command all merge cutadapt
# $ time smkp all_bam_chunks_merged.cutadapt.done --cluster-config cluster.yaml --cluster 'qsub -N {cluster.name} -l select={cluster.select}:ncpus={cluster.ncpus}:mem={cluster.mem} -e {cluster.error} -o {cluster.output}' --jobs 9999 --latency-wait 20
# Finished job 0.
# 145 of 145 steps (100%) done

#real    257m47.819s
#user    0m19.853s
#sys     0m41.761s


