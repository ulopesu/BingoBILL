// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "hardhat/console.sol";

uint constant qtd_nums = 5;
uint256 constant minValorCartela = 5;

struct Cartela {        // Cartelas distríbuidas antes do sorteio
    uint id;
    uint sorteioID;
    uint[qtd_nums] numeros;
    address jogador;
    bool premiada;
    bool emJogo;
}


function sortearNum(uint semente) view returns (uint) {
    // Resto da divisão por 100 do número do bloco atual 
    // + número em segundos da data e hora que o bloco foi fechado;
    return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, semente))) % 100;
}

function sortearNums() view returns (uint[qtd_nums] memory) {
    // Realiza o sorteio de todos os números sem permitir repetições
    // console.log("Numeros da Sorteados: ");

    uint[qtd_nums] memory nums;
    uint semente = 0;
    for (uint i = 0; i < qtd_nums; i++) {
        uint numSorteado = sortearNum(semente);
        // console.log(numSorteado);
        nums[i] = numSorteado;
        for (uint j = 0; j < i; j++) {
            if(numSorteado == nums[j]){
                i--;    // Número Repetido, sorteia novamente;
            }
        }
        semente++;
    }
    return nums;
}


contract Sorteio {
    uint sorteioID;
    uint[qtd_nums] numSorteados;    // Números sorteados

    uint totalCartelas;
    mapping(uint => Cartela) public cartelas;

    uint totalCartelasPremiadas;
    mapping(uint => Cartela) public cartelasPremiadas;

    enum Status{ CRIACAO, FINALIZADO }
    Status statusAtual;    // Status do Sorteio;
    
    constructor(uint _sorteioID) {
        statusAtual = Status.CRIACAO;
        totalCartelas = 0;
        totalCartelasPremiadas = 0;
        sorteioID = _sorteioID;
    }

    function addCartela(Cartela calldata _cartela) public {
        cartelas[totalCartelas] = _cartela;
        totalCartelas++;
    }

    function separarCartelasPremiadas() internal {
        bool cartela_premiada = true;
        for (uint i = 0; i < totalCartelas; i++) {
            Cartela memory cartela = cartelas[i];
            cartela.emJogo = false;

            for (uint j = 0; j < qtd_nums; j++) {
                uint numeroSorteado = numSorteados[j];
                for (uint k = 0; j < qtd_nums; k++) {
                    if(numeroSorteado != cartela.numeros[j]) {
                        cartela_premiada = false;
                        break;
                    }
                }

                if (cartela_premiada) {
                    cartelasPremiadas[totalCartelasPremiadas] = cartelas[i];
                    totalCartelasPremiadas++;
                } else {
                    cartela_premiada = true;
                    break;
                }
            }
        }
    }

    function finalizarSorteio() internal {
        numSorteados = sortearNums();
        separarCartelasPremiadas;
        // pagar Cartelas Premiadas;
        statusAtual = Status.FINALIZADO;
    }

}


contract BingoBILL {
    address addrAdmin = 0x89e66f9b31DAd708b4c5B78EF9097b1cf429c8ee;
    mapping(uint => Sorteio) public sorteios;
    uint totalSorteios;
    uint totalCartelas;
    string mssg = "Hello World!";

    constructor() {
        totalSorteios = 0;
        totalCartelas = 0;
        addSorteio();
    }

    function addSorteio() internal {
        totalSorteios++;
        sorteios[totalSorteios] = new Sorteio(totalSorteios);
    }

    modifier checkValor {
        require(
            msg.value >= minValorCartela,
            "Valor abaixo do minimo!"
        );
        _;
    }

    function comprarCartela() external payable checkValor {
        uint[qtd_nums] memory nums_cartela = sortearNums();
        Cartela memory cartela = Cartela(
            totalCartelas+1,
            totalSorteios,
            nums_cartela,
            msg.sender,
            false,
            true
        );
        totalCartelas++;

        Sorteio sorteio = Sorteio(sorteios[totalSorteios]);
        sorteio.addCartela(cartela);
    }
}
