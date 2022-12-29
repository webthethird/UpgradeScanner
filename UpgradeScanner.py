import subprocess
import os
import json
from time import sleep
from dotenv import load_dotenv

if __name__ == '__main__':
    load_dotenv()
    rpc_url = os.getenv("RPC_URL")  # Infura RPC URL is for Ethereum only right now
    f = open("./contracts.json", "r")
    contracts = json.loads(f.read())
    f.close()
    any_updates = False
    for address in contracts["ethereum"].keys():
        sleep(1)
        slot = contracts["ethereum"][address]["slot"]
        name = contracts["ethereum"][address]["name"]
        # Read implementation address from storage using known slot
        bash_command = f'cast storage --rpc-url={rpc_url} {address} {slot}'
        process = subprocess.Popen(bash_command.split(), stdout=subprocess.PIPE, text=True)
        output, error = process.communicate()
        if error:
            print(f"Error reading from storage for {address}: {name}")
            continue
        if "offset" not in contracts["ethereum"][address].keys():
            impl = "0x" + str(output).replace("\n", "")[26:]
        else:
            offset = contracts["ethereum"][address]["offset"]
            impl = "0x" + str(output).replace("\n", "")[66-2*(offset + 20):66-2*offset]
        if impl not in contracts["ethereum"][address]["implementations"]:
            print(f"New implementation found for {name}:\n{impl}")
            contracts["ethereum"][address]["implementations"].append(impl)
            any_updates = True
            # Download implementation source code for diffing
            impl_path = f"./implementations/{name.replace(' ', '').replace(':', '')}/{impl}"
            bash_command = f'cast etherscan-source -d {impl_path} {impl}'   # Requires ETHERSCAN_API_KEY in .env
            process = subprocess.Popen(bash_command.split(), stdout=subprocess.PIPE, text=True)
            output, error = process.communicate()
    if any_updates:
        f = open("./contracts.json", "w")
        f.write(json.dumps(contracts, indent=2, sort_keys=False))
        f.close()

