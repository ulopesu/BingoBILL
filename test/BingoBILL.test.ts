import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("BingoBILL", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const BingoBILL = await ethers.getContractFactory("BingoBILL");
    const contract = await BingoBILL.deploy();

    return { contract, owner, otherAccount };
  }

  it("ComprarCartela", async function () {
    const { contract, owner, otherAccount } = await loadFixture(deployFixture);

    // Pegar e imprimir o valor de contrato
    // const provider = ethers.getDefaultProvider();
    // let contract_balance = await provider.getBalance(contract.address);
    // console.log(contract.address);
    
    const valorPago = 70000000;
    const valorMinimo = BigInt("50000000000000000");
    const gorjetaDevPai = BigInt("10000000000000000");
    const configValorPago = { value: ethers.utils.parseUnits(`${valorPago}`,'gwei') };
  
    await contract.comprarCartela(configValorPago);
    await contract.comprarCartela(configValorPago);
    const sorteio = await contract.getSorteioAtualEXT();

    console.log(sorteio.balance);
    expect(sorteio.balance).to.equal((valorMinimo-gorjetaDevPai)*BigInt(2));
  });

  it("getCartelasJogador", async function () {
    const { contract, owner, otherAccount } = await loadFixture(deployFixture);

    const valorPago = BigInt("499999999999999999");
    const configValorPago = { value: ethers.utils.parseUnits(`${valorPago}`,'wei') };
    await contract.comprarCartela(configValorPago);
    await contract.comprarCartela(configValorPago);

    const cartelasJog = await contract.getCartelasJogador();

    // console.log(cartelasJog);

    expect(cartelasJog.length).to.equal(2);
  });

});