version 1.0

task fulltask {
  input {
    File R1
    File R2
    File reference
  }
  command <<<
    fastp -i ~{R1} -o R1.paired.fastq -I ~{R2} -O R2.paired.fastq -l 20 --cut_front --cut_tail --cut_front_window_size 4 --cut_front_mean_quality 30 -h report.html
    bowtie2-build ~{reference} ref_index
    bowtie2 -p 4 -x ref_index -1 R1.paired.fastq -2 R2.paired.fastq --very-sensitive -S result.sam
    samtools view --threads 4 -bT ~{reference} result.sam > result.bam  
    samtools sort result.bam -o result.sorted.bam 
    samtools index result.sorted.bam result.sorted.bam.bai
    samtools mpileup -d 9999999 -Q 0 --reference ~{reference} result.sorted.bam | ivar variants  -q 0 -t 0 -p ivar_table
    awk '{print $2,$3,$4,$11}' ivar_table.tsv > variants.txt
  
  >>>
  output {
    File result = "variants.txt"
  }
}
workflow reads_to_bam {
  input {
    File R1
    File R2
    File reference
  }
  call fulltask {
    input:
      R1 = R1,
      R2 = R2,
      reference = reference
    }
  output {
    File sorted_indexed_bam = fulltask.result
  }
}
