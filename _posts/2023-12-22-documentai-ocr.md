---
layout: post
comments: true
author: Manuel Capel
title: Trying OCR with GCloud Document AI
date: 2023-12-22
categories: [deep learning,cloud]
---
[OCR](https://en.wikipedia.org/wiki/Optical_character_recognition) stands for "Optical Character Recognition", and is a powerful technique for
extracting texts (and possibly also their position, fonts etc.) out of images.
This task is far from being trivial, given all the possible fonts, colors,
image qualities out there. The text may also not lay on a horizontal straight line...
Well you guess it, everything is possible in the wild, and the first
step to make sense out of it is to extract the characters.

Google has been very strong in this area over the last years, especially
through its open-source tool [Tesseract
OCR](https://github.com/tesseract-ocr/tesseract). This tool comes also in
wrappers for the Python or Go etc. programming language. It also scores high in
detection accuracy and support 100+ languages.

That's why I got very curious to try out the OCR capabilities served on the
[Document AI](https://cloud.google.com/document-ai) service of Google Cloud.

## Setup
First you have to log in the [Google Cloud
console](https://console.cloud.google.com/), select one of your projects
(or create a new one for that purpose) and activate *Document AI* for that
project. There you have to create a processor. Either you can create your own
processor, or chose one from the *Processor gallery*. I would recommend the
latter to start. At the moment you can create it in only in two regions, namely *us* and
*eu*. Once created, you the ID of your processor will be displayed. You will
need it.

Personally I create a general-purpose OCR processor in the *eu* region.

## For a local PDF file

If you want to try it out yourself, you can do it with this
[Python command-line tool](https://gist.github.com/mancap314/a96ae779eee07e6b9c940e8b72bb9c87).
Don't forget to follow the instruction at the beginning regarding `pip install`
and creation of a `.env` file. 

I try it with a 30 MB / 153 pages PDF file in English. 

Then I get an error related to quota limit, which makes sense. According to the
[doc](https://cloud.google.com/document-ai/quotas), online processing (what we
have just done through this script) accepts files of max 20 MB in size.

But batch processing accepts documents up to 1 GB, so let's try it out:

## For a batch of documents on GCloud Storage
For batch processing, your documents (PDF files) have to be stored in a bucket
on GCloud storage. So I uploaded 16 documents, between 3.5 and 30 MB. This
should keep was below the quota limits for batch processing.
(Code for a command-line tool in Python for Document AI OCR batch processing
available [here](https://gist.github.com/mancap314/a96ae779eee07e6b9c940e8b72bb9c87))
There I got an unclear error message back, related to some tokens in one of the
documents


## Conclusion
On the pro side:
- Large gallery of ready-to-use OCR processors
- Possibility to create / fine-tune your owm OCR processor, also with
  [Human-in-the-loop](https://livebook.manning.com/book/human-in-the-loop-machine-learning/)
- You can also define the fields you want back (Box positions etc.), allowing
  fine-granular post-processing (see *fieldMask* in the [output
  config](https://cloud.google.com/document-ai/docs/reference/rest/v1/DocumentOutputConfig))

Cons:
- Processor has to be created on the console. So no automated "Terraformed"
  deployment
- Quota limits not suited for industrial use

In brief, it's a top-notch engine, but imho. still lacking packaging and
integration for serious stuffs in production. It may come in a near future.

