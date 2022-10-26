#!/usr/bin/env nextflow

params.greeting = 'Hello world!'
greeting_ch = Channel.from(params.greeting)

process splitLetters {

  input:
  val x from greeting_ch

  output:
  file 'chunks_*' into letters_ch

  """
  printf '$x' | split -b 6 - chunks_
  """
}

process convertToUpper {
  input:
  file y from letters_ch.flatten()
  output:
  stdout into result

  """
  rev $y
  """
}

result.view()
