# -*- coding: utf-8 -*-

from __future__ import absolute_import
from __future__ import division, print_function, unicode_literals

import dataiku
from dataiku.customrecipe import *

from sumy.parsers.html import HtmlParser
from sumy.parsers.plaintext import PlaintextParser
from sumy.nlp.tokenizers import Tokenizer
from sumy.nlp.stemmers import Stemmer
from sumy.utils import get_stop_words

import nltk
nltk.download('punkt')

import unicodedata

##################################
# Input data
##################################

input_dataset = get_input_names_for_role('input_dataset')[0]
df = dataiku.Dataset(input_dataset).get_dataframe()


##################################
# Parameters
##################################

recipe_config = get_recipe_config()

text_column_name = recipe_config.get('text_column_name', None)
if text_column_name is None:
    raise ValueError("You did not choose a text column.")

n_sentences = recipe_config.get('n_sentences', None)
if n_sentences is None:
    raise ValueError("You did not set a number of sentences.")

##################################
# Summarization
##################################
lang = recipe_config.get('lang', 'english')
LANGUAGE = lang

def summarize(text,method):

    text = text.decode('UTF-8', errors='ignore')
    
    parser = PlaintextParser.from_string(text, Tokenizer(LANGUAGE))

    stemmer = Stemmer(LANGUAGE)

    if method == "textrank":
        from sumy.summarizers.text_rank import TextRankSummarizer as Summarizer
    elif method == "lexrank":    
        from sumy.summarizers.lex_rank import LexRankSummarizer as Summarizer         
    elif method == "KL":
        from sumy.summarizers.kl import KLSummarizer as Summarizer
    elif method == "LSA":
        from sumy.summarizers.lsa import LsaSummarizer as Summarizer 
    elif method == "sumbasic":
        from sumy.summarizers.sum_basic import SumBasicSummarizer as Summarizer
    
    summarizer = Summarizer(stemmer)
    summarizer.stop_words = get_stop_words(LANGUAGE)

    sentences = [str(s).decode('UTF-8',errors='ignore') for s in summarizer(parser.document, sentences_count=n_sentences)]
    return ' '.join(sentences)

# Adding a new column with computed summaries
df["textrank"] = [summarize(text,"textrank") for text in df[text_column_name].values]
df["lexrank"] = [summarize(text,"lexrank") for text in df[text_column_name].values]
df["KL"] = [summarize(text,"KL") for text in df[text_column_name].values]
df["LSA"] = [summarize(text,"LSA") for text in df[text_column_name].values]
df["sumbasic"] = [summarize(text,"sumbasic") for text in df[text_column_name].values]

# Write recipe outputs
output_dataset = get_output_names_for_role('output_dataset')[0]
dataiku.Dataset(output_dataset).write_with_schema(df)
