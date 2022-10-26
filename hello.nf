#!/usr/bin/env nextflow

params.greeting = 'Hello world!'
greeting_ch = Channel.from(params.greeting)


process convertToUpper {

  input:
  file y from letters_ch.flatten()

  output:
  stdout into result_ch


  """
  cat $y | tr '[a-z]' '[A-Z]'
  """

}

result_chr.view{ it }
