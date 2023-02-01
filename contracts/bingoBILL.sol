// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "hardhat/console.sol";
address constant devPaiAddr = 0x89e66f9b31DAd708b4c5B78EF9097b1cf429c8ee;

uint constant qtd_nums = 3;
uint256 constant minValorCartela = 50000000000000000;
uint256 constant gorjetaDevPai = 10000000000000000;

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


function sortearNum(uint semente, uint sementeGlobal) view returns (uint) {
    // Resto da divisão de um número pseudo-aleatório pela DIFICULDADE atual do jogo;
    return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, semente, sementeGlobal))) % dificuldade;
}

function checkNumDuplicado(uint numSorteado, uint qtdSorteada, uint[qtd_nums] memory nums) pure returns (uint) {
    // Em caso de duplicação seta o numSorteado 
    // para o próximo ainda não sorteado, de forma cíclica
    bool reset = false;
    for (uint j = 0; j <= qtdSorteada; j++) {
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

function sortearNums(uint sementeGlobal) view returns (uint[qtd_nums] memory) {
    // Realiza o sorteio de todos os números sem permitir repetições
    // console.log("Numeros da Sorteados: ");

    uint[qtd_nums] memory nums;
    uint semente = 0;
    for (uint i = 0; i < qtd_nums; i++) {
        uint numSorteado = sortearNum(semente, sementeGlobal);
        // console.log(numSorteado);
        nums[i] = checkNumDuplicado(numSorteado, i, nums);
        semente++;
    }
    return nums;
}


contract Sorteio {
    address bingoAddr;
    uint sorteioID;
    bool emJogo = true;             // Status do Sorteio;
    uint[qtd_nums] numSorteados;    // Números sorteados

    uint totalSorteioCartelas = 0;
    mapping(uint => Cartela) public cartelasSorteio;
    
    constructor(address _bingoAddr, uint _sorteioID, uint totalCartelas) {
        bingoAddr = _bingoAddr;
        sorteioID = _sorteioID;
        numSorteados = sortearNums(_sorteioID+totalCartelas);
    }

    modifier onlyDevPai {
        require(
            msg.sender == devPaiAddr,
            unicode"Permissão Negada!"
        );
        _;
    }

    modifier checarValor {
        require(
            msg.value >= minValorCartela - gorjetaDevPai,
            unicode"Valor abaixo do mínimo!"
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
        return totalSorteioCartelas;
    }

    function getBalance() view public returns (uint){
        return address(this).balance;
    }

    function addCartela(Cartela memory _cartela) public payable checarValor {
        totalSorteioCartelas++;
        cartelasSorteio[totalSorteioCartelas] = _cartela;
    }

    function checarCartelaPremiada(uint[qtd_nums] memory nums_cartela) view public returns (bool) {
        bool cartela_premiada = true;
        bool num_encontrado = false;

        for (uint j = 0; j < qtd_nums; j++) {
            uint numeroSorteado = numSorteados[j];

            for (uint k = 0; k < qtd_nums; k++) {
                if(numeroSorteado == nums_cartela[k]) {
                    num_encontrado = true;
                    break;
                }
            }

            if(!num_encontrado){
                cartela_premiada = false;
                break;
            }
            num_encontrado = false;
        }
        return cartela_premiada;
    }

    function pagarCartelaPremiada(Cartela memory cartela) public {
        if (cartela.sorteioID != sorteioID || !emJogo || !cartela.premiada) {
            return;
        }
        uint premio = address(this).balance;
        (bool enviado, ) = payable(cartela.jogador).call{value: premio}("");
        enviado = enviado;
        emJogo = false;
    }

    function resortearNums(uint totalCartelas) public onlyDevPai {
        numSorteados = sortearNums(totalCartelas);
    }
}


contract BingoBILL {
    mapping(uint => Sorteio) public sorteios;
    mapping(uint => Cartela) public cartelasBingo;

    mapping(address => uint) public totalCartelasJogador;

    uint totalSorteios;
    uint totalCartelas;

    constructor() {
        totalSorteios = 0;
        totalCartelas = 0;
        addSorteio();
    }

    event CompraCartelaLog(address indexed sender, string message);
    event GanhadorLog(address indexed sender, string message);

    modifier checarValor {
        require(
            msg.value >= minValorCartela,
            unicode"Valor abaixo do mínimo!"
        );
        _;
    }

    modifier onlyDevPai {
        require(
            msg.sender == devPaiAddr,
            unicode"Permissão Negada!"
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

    function addSorteio() internal returns (Sorteio) {
        totalSorteios++;
        Sorteio sorteio = new Sorteio(address(this), totalSorteios, totalCartelas);
        sorteios[totalSorteios] = sorteio;
        return sorteio;
    }

    function getSorteioAtualINT() view internal returns (Sorteio) {
        return sorteios[totalSorteios];
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

    function comprarCartela() external payable checarValor {
        totalCartelas++;
        Sorteio sorteio = getSorteioAtualINT();
        uint[qtd_nums] memory nums_cartela = sortearNums(totalCartelas);
        bool is_premiada = sorteio.checarCartelaPremiada(nums_cartela);
        Cartela memory cartela = Cartela(
            totalCartelas,
            totalSorteios,
            nums_cartela,
            msg.sender,
            is_premiada
        );
        sorteio.addCartela{value: (minValorCartela - gorjetaDevPai)}(cartela);
        cartelasBingo[totalCartelas] = cartela;
        totalCartelasJogador[msg.sender]++;
        if (!is_premiada) {
            emit CompraCartelaLog(msg.sender, "Cartela comprada com sucesso!");
            return;
        }
        sorteio.pagarCartelaPremiada(cartela);
        addSorteio();
        emit GanhadorLog(msg.sender, unicode"Parabéns, você ganhou!");
    }

    function getCartelasJogador() external view returns (Cartela[] memory) {
        uint qtdCartelasJog = totalCartelasJogador[msg.sender];
        Cartela[] memory cartelasJog = new Cartela[](qtdCartelasJog);

        uint cartelasEncontradas = 0;
        for (uint i = 1; i <= totalCartelas; i++) {
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

    function resortearNums() external onlyDevPai {
        Sorteio sorteio = sorteios[totalSorteios];
        sorteio.resortearNums(totalCartelas);
    }
}

// ULTIMA VERSÃO CONTRATO REMIX: 0xf067f30813830269Ab0fF9A42cD0cd9831a1901b