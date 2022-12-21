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
    const valorMinimo = 5;
    const configValorPago = { value: ethers.utils.parseUnits(`${valorMinimo}`,'wei') };
    await contract.comprarCartela(configValorPago);
    await contract.comprarCartela(configValorPago);
    const sorteio = await contract.getSorteioAtual();
    const sorteioBalance = await ethers.provider.getBalance(sorteio);
    expect(sorteioBalance).to.equal(valorMinimo*2);
  });

  it("getCartelasJogador", async function () {
    const { contract, owner, otherAccount } = await loadFixture(deployFixture);

    const valorMinimo = 5;
    const configValorPago = { value: ethers.utils.parseUnits(`${valorMinimo}`,'wei') };
    await contract.comprarCartela(configValorPago);
    await contract.comprarCartela(configValorPago);

    const cartelasJog = await contract.getCartelasJogador();

    expect(cartelasJog.length).to.equal(2);
  });

});