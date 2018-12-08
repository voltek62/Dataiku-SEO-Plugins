# Text Summarization

Inspired from : https://github.com/dataiku/dataiku-contrib/tree/master/text-summarization
- Test all summarization methods foreach rows
- Add 3 new methods
- Fix encoding problems with UTF-8
- Choose your language

------------------------------

This plugin provides a tool for doing automatic text summarization. It uses extractive summarization methods, which means that the summary will be a number of extracted sentences from the original input text. This can be used for example to summarize customer reviews or long reports into shorter texts.

## Recipes
### Summarize Texts

This recipe summarizes your texts using all summarization techniques (Text Rank, KL-Sum and LSA).

**How to use the recipe**
Using the recipe is straightforward. First plug in your dataset and select the column containing your texts. Then, select a method, set the number of desired sentences and run the recipe!