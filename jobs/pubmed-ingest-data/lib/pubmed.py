import requests
import xml.etree.ElementTree as ET
import time
import urllib.parse

def search_pubmed(terms):
    base_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"

    # Prepare the 'term' query parameter by enclosing each term in brackets and adding ' OR ' between them
    formatted_terms = " OR ".join([f"({urllib.parse.quote(str(term))})" for term in terms])
    
    # Define the parameters for the request
    params = {
        'db': 'pubmed',
        'retmode': 'json',
        'retmax': '1000',
        'term': formatted_terms
    }

    print(params)
    
    # Make the GET request to the PubMed API
    response = requests.get(base_url, params=params)
    
    # Check if the request was successful
    if response.status_code == 200:
        data = response.json()

        # Check if 'esearchresult' is in the response and return it
        if 'esearchresult' in data:
            print(data['esearchresult'])
            return data['esearchresult']
        else:
            return {"error": "'esearchresult' not found in the response"}
    else:
        return {"error": f"Request failed with status code {response.status_code}"}

def fetch_pubmed_abstracts(idlist):
    base_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"
    db_param = {'db': 'pubmed', 'rettype': 'abstract'}
    
    # Function to handle a single batch of IDs (up to 30 IDs at a time)
    def fetch_batch(ids):
        id_str = ','.join(map(str, ids))  # Comma-delimited string of IDs
        params = {**db_param, 'id': id_str}
        
        response = requests.get(base_url, params=params)
        
        if response.status_code == 200:
            return response.text  # Return the raw response text (XML format)
        else:
            return ""
    
    # Function to parse XML and extract required fields
    def parse_pubmed_article(article):
        output = {}
        ns = {'ns': 'http://www.ncbi.nlm.nih.gov'}

        try:
            # Parse the XML and extract necessary data
            
            # Extract Article IDs
            #article_ids = [f"{article.get('IdType'): {article.text}}" for article in article.findall(".//PubmedData/ArticleIdList/ArticleId")]
            # article_ids = [f"{article.get('IdType')}: {article.text}" for article in article.findall(".//PubmedData/ArticleIdList/ArticleId")]
            # article_ids_text = ', '.join(article_ids)


            for article_id in root.findall('.//PubmedData/ArticleIdList/ArticleId'):
                id_type = article_id.attrib.get('IdType')
                id_value = article_id.text
                output[id_type] = id_value

                # sample
                # 'pubmed': '39173398',
                # 'doi': '10.1016/j.vetimm.2024.110816',
                # 'pii': 'S0165-2427(24)00102-8'

            output['pmid'] = article.findtext('.//PMID')
            output['title'] = article.findtext('.//ArticleTitle')

            pub_date = ''
            try:
                pub_year = article.findtext(".//DateRevised/Year")
                pub_month = article.findtext(".//DateRevised/Month")
                pub_day = article.findtext(".//DateRevised/Day").zfill(2)  # Ensure two-digit day format
                pub_date = f"{pub_year}-{pub_month}-{pub_day}"
            except Exception as e:
                print('Pub date', e)
                print('article', article)
            output['pubDate'] = pub_date
            # Extract Abstract text
            # abstract_texts = [abstract.text for abstract in article.findall(".//AbstractText")]
            # abstract_text = ' '.join(abstract_texts)

            try:
                abstract_text_elements = article.findall('.//AbstractText')
                output['abstract'] = ' '.join([ET.tostring(e, encoding='unicode', method='text') for e in abstract_text_elements]) if len(abstract_text_elements) == 0 else ''

            except Exception as e:
                print('Abstract', e)
                print('article', article)

            try:
                # Extract authors' names from the AuthorList
                authors = []
                for author in article.findall('.//Author'):
                    last_name = author.findtext('.//LastName')
                    fore_name = author.findtext('.//ForeName')
                    if last_name and fore_name:
                        authors.append(f"{fore_name} {last_name}")
                output['authors'] = ', '.join(authors) if authors is not None and len(authors) > 0 else ''
            
            except Exception as e:
                print('Author', e)
                print('article', article)
            
            try:
                # Extract keywords
                keywords = [keyword.text for keyword in article.findall('.//Keyword')]
                output['keywords'] = ', '.join(keywords) if keywords is not None and len(keywords) > 0 else []
            except Exception as e:
                print('keywords', e)
                print('article', article)
            return output
        except Exception as e:
            print(f'Error while extracting, error message: {e}')

        return None
    
    # Split the list into chunks of 30 IDs
    results = []
    for i in range(0, len(idlist), 30):
        batch = idlist[i:i+30]  # Get a batch of up to 10 IDs
        batch_xml = fetch_batch(batch)
        
        if batch_xml != '':
            # Parse the XML response
            root = ET.fromstring(batch_xml)
            for article in root.findall('.//PubmedArticle'):
                parsed_article = parse_pubmed_article(article)
                if parsed_article is not None:
                    results.append(parsed_article)
        time.sleep(5)
    return results