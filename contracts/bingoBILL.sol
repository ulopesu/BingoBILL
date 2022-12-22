// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "hardhat/console.sol";

uint constant qtd_nums = 3;
uint256 constant minValorCartela = 5;
uint256 constant gorjetaDevPai = 1;

uint constant dificuldade = 8;

struct Cartela {        // Cartelas distríbuidas antes do sorteio
    uint id;
    uint sorteioID;
    uint[qtd_nums] numeros;
    address jogador;
    bool premiada;
}

struct SorteioInfo {        // Cartelas distríbuidas antes do sorteio
    address sorteioAddr;
    uint sorteioID;
    uint[qtd_nums] numSorteados;
    bool emJogo;
    uint totalCartelas;
    uint balance;
}


function sortearNum(uint semente) view returns (uint) {
    // Resto da divisão por DIFICULDADE do número do bloco atual 
    // + número em segundos da data e hora que o bloco foi fechado;
    return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, semente))) % dificuldade;
}

function checkNumDuplicado(uint numSorteado, uint qtdSorteada, uint[qtd_nums] memory nums) pure returns (uint) {
    // Em caso de duplicação seta o numSorteado 
    // para o próximo ainda não sorteado, de forma cíclica
    bool reset = false;
    for (uint j = 0; j < qtdSorteada; j++) {
        if (reset) {
            j = 0;
            reset = false;
        }
        if(numSorteado == nums[j]){
            numSorteado++;
            if(numSorteado >= dificuldade) {
                numSorteado = 0;
            }
            reset = true;
        }
    }
    return numSorteado;
}

function sortearNums() view returns (uint[qtd_nums] memory) {
    // Realiza o sorteio de todos os números sem permitir repetições
    // console.log("Numeros da Sorteados: ");

    uint[qtd_nums] memory nums;
    uint semente = 0;
    for (uint i = 0; i < qtd_nums; i++) {
        uint numSorteado = sortearNum(semente);
        // console.log(numSorteado);
        nums[i] = checkNumDuplicado(numSorteado, i, nums);
        semente++;
    }
    return nums;
}


contract Sorteio {
    address bingoAddr;
    uint sorteioID;
    uint[qtd_nums] numSorteados;    // Números sorteados

    uint totalCartelas = 0;
    mapping(uint => Cartela) public cartelasSorteio;

    bool emJogo = true;             // Status do Sorteio;
    
    constructor(address _bingoAddr, uint _sorteioID) {
        bingoAddr = _bingoAddr;
        sorteioID = _sorteioID;
        numSorteados = sortearNums();
    }

    modifier checarValor {
        require(
            msg.value >= minValorCartela - gorjetaDevPai,
            "Valor abaixo do minimo!"
        );
        _;
    }

    function getAddress() view public returns (address){
        return address(this);
    }

    function getID() view public returns (uint){
        return sorteioID;
    }

    function getStatus() view public returns (bool){
        return emJogo;
    }

    function getNumSorteados() view public returns (uint[qtd_nums] memory){
        return numSorteados;
    }

    function getTotalCartelas() view public returns (uint){
        return totalCartelas;
    }

    function getBalance() view public returns (uint){
        return address(this).balance;
    }

    function addCartela(Cartela memory _cartela) public payable checarValor {
        cartelasSorteio[totalCartelas] = _cartela;
        totalCartelas++;
        checarCartelaPremiada(_cartela);
    }

    function checarCartelaPremiada(Cartela memory _cartela) internal {
        bool cartela_premiada = true;

        for (uint j = 0; j < qtd_nums; j++) {
            uint numeroSorteado = numSorteados[j];
            for (uint k = 0; j < qtd_nums; k++) {
                if(numeroSorteado != _cartela.numeros[j]) {
                    cartela_premiada = false;
                    break;
                }
            }

            if (!cartela_premiada) {
                break;
            }
        }

        if (cartela_premiada) {
            _cartela.premiada = true;
            pagarCartelaPremiada(_cartela);
        } 
    }

    function pagarCartelaPremiada(Cartela memory cartelaPremiada) internal {
        uint premio = address(this).balance;
        (bool enviado, ) = payable(cartelaPremiada.jogador).call{value: premio}("");
        enviado = enviado;
    }
}


contract BingoBILL {
    address devPaiAddr = 0x89e66f9b31DAd708b4c5B78EF9097b1cf429c8ee;
    mapping(uint => Sorteio) public sorteios;
    mapping(uint => Cartela) public cartelasBingo;

    mapping(address => uint) public totalCartelasJog;

    uint totalSorteios;
    uint totalCartelas;

    constructor() {
        totalSorteios = 0;
        totalCartelas = 0;
        addSorteio();
    }

    modifier checarValor {
        require(
            msg.value >= minValorCartela,
            "Valor abaixo do minimo!"
        );
        _;
    }

    modifier onlyDevPai {
        require(
            msg.sender == devPaiAddr,
            "Permissao Negada!"
        );
        _;
    }

    function pagarDevPai() external onlyDevPai returns (bool){
        uint balance = address(this).balance;
        bool enviado = false;
        if(balance > 0) {
            (enviado, ) = payable(devPaiAddr).call{value: balance}("");
        }
        return enviado;
    }

    function addSorteio() internal {
        totalSorteios++;
        sorteios[totalSorteios] = new Sorteio(address(this), totalSorteios);
    }

    function getSorteioAtualINT() internal view returns (Sorteio) {
        Sorteio sorteio = sorteios[totalSorteios];
        return sorteio;
    }

    function getSorteioAtualEXT() external view returns (SorteioInfo memory) {
        Sorteio sorteio = sorteios[totalSorteios];
        SorteioInfo memory sorteioInfo = SorteioInfo(
            sorteio.getAddress(),
            sorteio.getID(),
            sorteio.getNumSorteados(),
            sorteio.getStatus(),
            sorteio.getTotalCartelas(),
            sorteio.getBalance()
        );

        return sorteioInfo;
    }

    //  struct SorteioInfo {        // Cartelas distríbuidas antes do sorteio
    //      address sorteioAddr;
    //      uint sorteioID;
    //      uint[qtd_nums] numSorteados;
    //      bool emJogo;
    //      uint totalCartelas;
    //      uint balance;
    //  }

    function comprarCartela() external payable checarValor {
        uint[qtd_nums] memory nums_cartela = sortearNums();
        Cartela memory cartela = Cartela(
            totalCartelas+1,
            totalSorteios,
            nums_cartela,
            msg.sender,
            false
        );
        totalCartelas++;

        Sorteio sorteio = getSorteioAtualINT();
        if (!sorteio.getStatus()){
            addSorteio();
            sorteio = getSorteioAtualINT();
        }

        sorteio.addCartela{value: minValorCartela - gorjetaDevPai}(cartela);
        cartelasBingo[totalCartelasJog[msg.sender]++] = cartela;
    }

    function getCartelasJogador() external view returns (Cartela[] memory) {
        uint qtdCartelasJog = totalCartelasJog[msg.sender];
        Cartela[] memory cartelasJog = new Cartela[](qtdCartelasJog);

        uint cartelasEncontradas = 0;
        for (uint i = 0; i < totalCartelas; i++) {
            Cartela memory cartela = cartelasBingo[i];
            if (cartela.jogador == msg.sender) {
                cartelasJog[cartelasEncontradas] = cartela;
                cartelasEncontradas++;
            }
            if(cartelasEncontradas == qtdCartelasJog) {
                break;
            }
        }

        return cartelasJog;
    }
}

// ULTIMA VERSÃO CONTRATO REMIX: 0x9C0A474644bEA63A704cD5C93ca0429eA19EF5Bb