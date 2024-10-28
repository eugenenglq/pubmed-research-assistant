import json

class BedrockEmbedding:
    def __init__(self, bedrock_client, embedding_model_id='amazon.titan-embed-text-v2:0', index_name=''):
        self.bedrock_client = bedrock_client
        self.index_name = index_name
        self.embedding_model_id = embedding_model_id
        self.accept = "application/json"
        self.content_type = "application/json"

    def create_vector_embedding(self, pmid, title, abstract, pubDate, authors, keywords, pubmed, pmc, doi, pii):
        # body = json.dumps({
        #     "texts": [f"Title: {title}\n\n Abstract: {abstract}\n\n Authors: {authors} \n\n PMCID: {pmc} "],  # Note that 'texts' expects a list of strings
        #     "input_type": "search_document"  # This is a common input type, but check the specific model's documentation
        # })

        body = json.dumps({
            "inputText": f"Title: {title}\n\n Abstract: {abstract}\n\n Authors: {authors} \n\n PMCID: {pmc} ",  # Note that 'texts' expects a list of strings
        })
        print(body)

        response = self.bedrock_client.invoke_model(
            body=body,
            modelId=self.embedding_model_id,
            accept=self.accept,
            contentType=self.content_type
        )
        response_body = json.loads(response.get("body").read())

        embedding = response_body.get("embedding")
        returnobj = {
            "_index": self.index_name,
            "pmid": pmid,
            "title": title,
            "text": abstract,
            "vector_field": embedding,
            'authors': authors,
            'keywords': keywords,
            'pubmed': pubmed,
            'pmc': pmc,
            'doi': doi,
            'pii': pii
        }

        if pubDate != '':
            returnobj['pubDate'] = pubDate

        return returnobj
