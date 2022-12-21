# BingoBILL Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```


# Informações Gerais

## Descreva o domínio da aplicação e o problema que a DApp visa resolver?

Aplicação irá funcionar como um jogo de bingo, com as seguintes características:
    1 - Sorteio Automático;
    2 - Sorteio a cada 5 minutos;
    3 - Sorteio de 5 números entre 0 a 99;
    4 - Peenchimento automático da cartela com 5 números aleatórios;
    5 - Cartela com preço fixo;
    6 - É permitida a compra de somente uma cartela por jogador em cada sorteio;
    7 - Os jogadores ganhadores receberão, ao final de cada sorteio, o dividendo de todo o montante acumulado das cartelas vendidas;

Benefícios:
    1 - Facilidade de participar;
    2 - Segurança contra trapaças e golpes, por parte de outros jogadores ou organização do bingo;
    3 - Maior agilidade entre cada sorteio em comparação com um jogo de bingo manual;


## Como (para que) você irá usar o conceito de Contract Factory?

O conceito de Contract Factory será utilizado para fazer com que cada sorteio realizado seja um novo contrato, 
dessa maneira cada rodada realizada ficará salva em um único contrato, garantindo uma independencia entre as rodadas, 
o que também ajuda a mitigar possíveis erros da aplicação.


## Como (para que) você irá usar o conceito de Events?

Os Events serão usados para interagir com a interface gráfica 
noticando ao usuário as etapas do sorteio e o resultado do mesmo.
