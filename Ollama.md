OLLAMA LOCAL chat imlementation - currently used qwen3:14b
#bellow are the first encouters with local LLM

Install the LLM locally
curl -fsSL https://ollama.com/install.sh | sh

qwen3:14b is running at the moment

ollama pull nameofwhateverLLMmodel
ollama run nameofwhateverLLMmodel #once it runs, you can get out of the CLI with CTRL+D
The LLM still remains active in backround because ollama run has been executed. To get back to CLI hit ollama run modelname again and you are back

CTRL+C to exit the running prompt if it is too long
ollama stop nameofwhateverLLMmodel  #you are unloading the LLM from RAM
ollama stop --all #if you are running multiple models
ollama ps to see usage


Now that the LLM runs in the backournd, there is a Daemon that runs on localhost
Practically when you run the LLM, ollama runs "ollama serve" command automatically and an localhost endpoint is created - http://localhost:11434/api/version
you can curl into it: curl http://localhost:11434/api/version


You can now ask in the CLI whatever

Interactive sesisons in terminal cannot be redirected directly

You can append to files >> using the followin commands
ollama run qwen3:14b "Explain Init Containers" >> notes.md

You can log everything in this way:
ollama run qwen3:14b | tee convo.txt

to adress where is ollama running
sudo ss -tulpn | grep 11434


#########################
RAG
mkdir local-rag
cd local-rag
python3 -m venv venv
source venv/bin/activate

#install RAG libraries
pip install llama-index llama-index-llms-ollama llama-index-embeddings-ollama

Create app.py

```
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.llms.ollama import Ollama

llm = Ollama(model="qwen2.5:14b")

documents = SimpleDirectoryReader("data").load_data()
index = VectorStoreIndex.from_documents(documents)
query_engine = index.as_query_engine(llm=llm)

while True:
    q = input("Ask: ")
    print(query_engine.query(q))

```
python app.py
Ask: how do I create an ECS Fargate service using Terraform?
#Add a webchat UI with one command

pip install llama-index-llama-agents

Map the directory of Obsidian where I keep my notes to ollama where I should move Obsidian data but I do not want to
ln -s "/mnt/c/Users/<username>/ObsidianVault" ./data/vault
ls data/vault

Modify RAG script app.py

```
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.llms.ollama import Ollama
from llama_index.embeddings.ollama import OllamaEmbedding

# Use same model for reasoning and embeddings (simplest baseline)
llm = Ollama(model="qwen2.5:14b")
embed_model = OllamaEmbedding(model_name="qwen2.5:14b")

# Load all notes inside data/ including subfolders
documents = SimpleDirectoryReader("data").load_data()

# Create vector index (semantic search knowledge base)
index = VectorStoreIndex.from_documents(documents, embed_model=embed_model)

# Query engine to answer questions using your notes
query_engine = index.as_query_engine(llm=llm)

print("✅ RAG ready. Ask anything from your notes.")
while True:
    q = input("\nAsk: ")
    response = query_engine.query(q)
    print("\n" + str(response) + "\n")

```
python app.py and test it
Ask: explain helm charts using my own words from my notes
Ask: how do I configure VPC Endpoints again?
Ask: what was that trick with kubectl port-forward?

###########
Running RAG + chatUI ( bellow RAG is not yet finished)

#If you do not have the image it will pull it. 
#if you cannot find the docker container (failed) run docker logs container ID (docker ps -a   to see all (even not working or crashed ones ) to get the container id)
#see what returns

#create a folder for the persisten data or the container 
mkdir -p ~/anythingllm-data
ls ~
the bellow command is ( for WSL2 !)
docker stop anythingllm
docker rm anythingllm

See ip bindings in WSL2, Docker -> WSL -> Windows
ip route | grep docker0
hostname -I

Run first time anythingLLM in docker container for Ollama to use the UI
docker run -d \
  -p 3000:3000 \
  -p 3001:3001 \
  -e HOST=0.0.0.0 \
  -e UI_ENABLED=true \
  -e STORAGE_DIR="/app/server/storage" \
  -v ~/anythingllm-data:/app/server/storage \
  --name anythingllm \
  mintplexlabs/anythingllm

  ollama list  # to see which model are you running

curl http://localhost:11434/api/version

curl http://localhost:3000 # this is the backend

curl http://localhost:3001  # this is frontend where you configure the local adress of the LLM that you get from sudo ss -tulpn | grep 11434

sudo ss -tulpn | grep 11434  #11434 is de default port for Ollama


ps aux | grep ollama
sudo systemctl stop ollama  or  sudo kill -9 PID
Or restart it
sudo systemctl daemon-reload
sudo systemctl restart ollama

sudo systemctl disable ollama # so it cannot start on its own with the terminal startup
systemctl status ollama  # see if it is active


lscpu | grep '^CPU(s):'  #get how many cores CPU has



the bellow command will work in the future when persisten data is created
docker run -d -p 3000:8080 mintplexlabs/anythingllm

If you need to kill it 
sudo pkill ollama
ps aux | grep ollama
sudo systemctl start ollama

htop
top -o %MEM #this is better for live view
ps aux --sort=-%mem | grep ollama

Continue  in OLLAMA TO CHAT

