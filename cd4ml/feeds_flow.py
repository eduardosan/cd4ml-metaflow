# %load ../cd4ml/feeds_flow.py

import feedparser
import pandas as pd
import re

from nltk import word_tokenize
from nltk.corpus import stopwords

import string
import pendulum

from metaflow import FlowSpec, step

class FeedsFlow(FlowSpec):

    @step
    def start(self):
        self.feeds_url = [
            'https://feeds.folha.uol.com.br/emcimadahora/rss091.xml',
            'https://g1.globo.com/rss/g1/',
            'https://g1.globo.com/rss/g1/brasil'
        ]
        self.next(self.fetch_feed_data, foreach='feeds_url')

    @step
    def fetch_feed_data(self):
        
        print(f"Downloading from url {self.input}")
        blog_feed = feedparser.parse(self.input)

        posts = blog_feed.entries  
        post_list = []

        for post in posts:
            post_dict = dict()

            post_dict["TITLE"] = post.title
            post_dict["CONTENT"] = post.summary
            post_dict["LINK"] = post.link
            post_dict["TIME_PUBLISHED"] = post.published
            # post_dict["TAGS"] = [tag.term for tag in post.tags]
            
            # First date conversion try:
            dt = None
            try:
                dt = pendulum.from_format(post.published, 'DD MMM YYYY HH:mm:ss ZZ') 
            except ValueError as e:
                dt = pendulum.from_format(post.published, 'ddd, DD MMM YYYY HH:mm:ss ZZ')
            except ValueError as e:
                print(f"Formating error!\n{e}")
            post_dict['PUBLISHED'] = dt

            post_list.append(post_dict)
        self.posts = pd.DataFrame(post_list)        
        self.next(self.feeds_aggregate)

    @step
    def feeds_aggregate(self, inputs):
        self.results = pd.concat([input.posts for input in inputs])
        self.next(self.preprocess_pandas)
              
    @step
    def preprocess_pandas(self):
        stop = set(stopwords.words('portuguese') + list(string.punctuation))
        stop.update(['http', 'pro', 'https', 't.', 'co'])

        def preprocess(words):
            # Remove HTML marks
            words = re.sub('<.*?>|&([a-z0-9]+|#[0-9]{1,6}|#x[0-9a-f]{1,6});', '', words)
            tokens = word_tokenize(words)
            tokens = [word for word in tokens if word not in stop]
            tokens = [word for word in tokens if re.search(r'\w+', word) and len(word) > 2]
            return tokens
    
        self.results['token_set'] = self.results.apply(lambda row: preprocess(row.CONTENT.lower()), axis=1)
        print("Tokenization finished!")
        self.next(self.end)
    
    @step
    def end(self):
        print('Workflow finished!')
        
if __name__ == '__main__':
    FeedsFlow()
