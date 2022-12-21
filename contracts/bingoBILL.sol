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
    mapping(uint => Cartela) public cartelasSorteio;

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

    modifier checarValor {
        require(
            msg.value >= minValorCartela,
            "Valor abaixo do minimo!"
        );
        _;
    }

    function addCartela(Cartela calldata _cartela) public payable checarValor {
        cartelasSorteio[totalCartelas] = _cartela;
        totalCartelas++;
    }

    function separarCartelasPremiadas() internal {
        bool cartela_premiada = true;
        for (uint i = 0; i < totalCartelas; i++) {
            Cartela memory cartela = cartelasSorteio[i];
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
                    cartela.premiada = true;
                    cartelasPremiadas[totalCartelasPremiadas] = cartela;
                    totalCartelasPremiadas++;
                } else {
                    cartela_premiada = true;
                    break;
                }
            }
        }
    }

    function pagarCartelasPremiadas() internal {
        uint balance = address(this).balance;
        uint premio = balance / totalCartelasPremiadas;
        
        for (uint i = 0; i < totalCartelasPremiadas; i++){
            Cartela memory cartela = cartelasPremiadas[i];
            (bool enviado, ) = payable(cartela.jogador).call{value: premio}("");
            enviado = enviado;
        }
    }

    function finalizarSorteio() public {
        numSorteados = sortearNums();
        separarCartelasPremiadas();
        pagarCartelasPremiadas();
        statusAtual = Status.FINALIZADO;
    }

}


contract BingoBILL {
    mapping(uint => Sorteio) public sorteios;
    mapping(uint => Cartela) public cartelasBingo;

    mapping(address => uint) public totalCartelasJog;

    uint totalSorteios;
    uint totalCartelas;
    uint256 ultimoSorteioTime;

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

    function pagarDevPai() internal {
        address devPaiAddr = 0x89e66f9b31DAd708b4c5B78EF9097b1cf429c8ee;
        uint balance = address(this).balance;
        if(balance > 0) {
            (bool enviado, ) = payable(devPaiAddr).call{value: balance}("");
            enviado = enviado;
            // console.log("Enviado: ", enviado);
        }
    }

    function addSorteio() internal {
        totalSorteios++;
        sorteios[totalSorteios] = new Sorteio(totalSorteios);
        ultimoSorteioTime = block.timestamp;
    }

    function getSorteioAtual() public view returns (Sorteio) {
        Sorteio sorteio = Sorteio(sorteios[totalSorteios]);
        return sorteio;
    }

    function ciclarSorteio() internal {
        // FUNÇÃO UTILIZADA PARA FAZER COM QUE 
        // OS SORTEIOS OCORRAM A CADA 5 MINITOS
        if (block.timestamp - ultimoSorteioTime < 5 minutes) {
            return;
        }
        Sorteio sorteio = getSorteioAtual();
        sorteio.finalizarSorteio();
        pagarDevPai();
    }

    function comprarCartela() external payable checarValor {
        ciclarSorteio();

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

        Sorteio sorteio = getSorteioAtual();
        sorteio.addCartela{value: minValorCartela}(cartela);

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
