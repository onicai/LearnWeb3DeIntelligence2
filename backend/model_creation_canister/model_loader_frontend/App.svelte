<script lang="ts">
https://forum.dfinity.org/t/install-code-easiest-way-to-convert-a-wasm-module-to-nat8/18919/2
export const loadWasm = async (type) => {
  const buffer = await readFile(`${process.cwd()}/.dfx/local/canisters/${type}/${type}.wasm`);
  return [...new Uint8Array(buffer)];
};

const installWasm = async ({actor, type, wasmModule}) => {
  console.log(`Installing ${type} wasm code in manager.`);

  const chunkSize = 700000;

  const upload = async (chunks) => {
    const result = await actor.storageLoadWasm(chunks); // <---- here call of above Motoko endpoint
    console.log('Chunks:', result);
  };

  for (let start = 0; start < wasmModule.length; start += chunkSize) {
    const chunks = wasmModule.slice(start, start + chunkSize);
    await upload(chunks);
  }

  console.log(`Installation ${type} done.`);
};
  
</script>

<div class="App">
</div>
