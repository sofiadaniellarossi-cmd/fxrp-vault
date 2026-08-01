// fetch-ftso.js
// Lectura real y directa del FTSOv2 de Flare en Coston2.
// No depende del contrato FXRPVault ni del frontend: es prueba independiente
// de que el proyecto sabe hablar con el oráculo de Flare de verdad.
//
// Uso:   npm install ethers
//        node fetch-ftso.js

const { ethers } = require("ethers");

const RPC_URL = "https://coston2-api.flare.network/ext/C/rpc";
// Misma dirección en Flare, Coston2, Songbird y Coston (confirmado en dev.flare.network).
const REGISTRY_ADDRESS = "0xaD67FE66660Fb8dFE9d6b1b4240d8650e30F6019";
// bytes21: categoría 1 (crypto) + "XRP/USD" + padding a 21 bytes.
const XRP_USD_FEED_ID = "0x015852502f55534400000000000000000000000000";

const registryAbi = ["function getContractAddressByName(string) view returns (address)"];
const ftsoAbi = ["function getFeedById(bytes21) view returns (uint256,int8,uint64)"];

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const registry = new ethers.Contract(REGISTRY_ADDRESS, registryAbi, provider);

  const ftsoV2Address = await registry.getContractAddressByName("FtsoV2");
  const ftso = new ethers.Contract(ftsoV2Address, ftsoAbi, provider);

  const [value, decimals, timestamp] = await ftso.getFeedById(XRP_USD_FEED_ID);
  const price = Number(value) / 10 ** Number(decimals);

  console.log(`FtsoV2 resuelto vía registry en: ${ftsoV2Address}`);
  console.log(`XRP/USD: $${price.toFixed(4)}`);
  console.log(`Timestamp on-chain: ${new Date(Number(timestamp) * 1000).toISOString()}`);
}

main().catch((err) => {
  console.error("Error consultando el FTSOv2:", err);
  process.exit(1);
});
