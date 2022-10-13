
import feedparser
import pandas as pd

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

            post_list.append(post_dict)
        self.posts = pd.DataFrame(post_list)        
        self.next(self.feeds_aggregate)

    @step
    def feeds_aggregate(self, inputs):
        self.results = pd.concat([input.posts for input in inputs])
        self.next(self.end)
              
    @step
    def end(self):
        print('Workflow finished!')
        
if __name__ == '__main__':
    FeedsFlow()
