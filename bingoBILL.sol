// SPDX-License-Identifier: GPL-3.0
import "hardhat/console.sol";


pragma solidity ^0.8.0;

uint constant qtd_nums = 5;
uint256 constant valorCartela = 5;

struct Cartela {        // Cartelas distríbuidas antes do sorteio
    uint id;
    uint sorteioID;
    uint[qtd_nums] numeros;
    address jogador;
    bool premiada;
    bool emJogo;
}


function sortearNum() view returns (uint) {
    // Resto da divisão por 100 do número do bloco atual 
    // + número em segundos da data e hora que o bloco foi fechado;
    return uint((block.number + block.timestamp) % 100);
}

function sortearNums() view returns (uint[qtd_nums] memory) {
    // Realiza o sorteio de todos os números sem permitir repetições
    uint[qtd_nums] memory nums;
    for (uint i = 0; i < qtd_nums; i++) {
        uint numSorteado = sortearNum();
        nums[i] = numSorteado;
        for (uint j = 0; j < i; j++) {
            if(numSorteado == nums[j]){
                i--;    // Número Repetido, sorteia novamente;
            }
        }
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

    constructor() {
        totalSorteios = 0;
        totalCartelas = 0;
        addSorteio();
    }

    function addSorteio() internal {
        sorteios[totalSorteios] = new Sorteio(totalSorteios+1);
        totalSorteios++;
    }

    event Received(address, uint);

    function comprarCartela() external payable {
        // require(msg.value == valorCartela, "Membro nao encontrado!");
        console.log("0");

        emit Received(msg.sender, msg.value);

        console.log("1");

        Cartela memory cartela = Cartela(
            totalCartelas+1,
            totalSorteios,
            sortearNums(),
            msg.sender,
            false,
            true
        );
        totalCartelas++;

        console.log("2");

        Sorteio sorteio = sorteios[totalSorteios];
        sorteio.addCartela(cartela);

        console.log("3");
    }
}