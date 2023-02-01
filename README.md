# BingoBILL

# Informações Gerais

## Descreva o domínio da aplicação e o problema que a DApp visa resolver?
    1 - Cada sorteio possuí 3 números aleatórios entre 0 a 7;
    2 - Cada cartela também preenchida com 3 números aleatórios entre 0 a 7;
    3 - Uma cartela é considerada premiada se ela conter, em qualquer ordem, os 3 números do sorteio atual;
    4 - Um novo sorteio se inicia sempre que um jogador ganha, ou seja, compra uma cartela premiada;
    5 - Somente um jogador ganha a cada sorteio;
    6 - A probabilidade de um jogador comprar a cartela premiada é 1/C(8,3) = 1/56;
    7 - Os jogadores podem comprar qualquer quantidade de cartelas antes que o sorteio acabe;
    8 - As cartelas tem um preço fixo (0,05 Goerli);
    9 - O jogador ganhador recebe o montante acumulado das cartelas vendidas menos a gorgeta do DevPai;

Benefícios:
    1 - Facilidade de participar;
    2 - Segurança contra trapaças e golpes, por parte de outros jogadores ou organização do jogo;
    3 - Maior agilidade entre cada sorteio em comparação com um jogo manual;


## Como (para que) você irá usar o conceito de Contract Factory?

O conceito de Contract Factory será utilizado para fazer com que cada sorteio realizado seja um novo contrato, 
dessa maneira cada rodada realizada ficará salva em um único contrato, garantindo uma independencia entre as rodadas, 
o que também ajuda a mitigar possíveis erros da aplicação.


## Como (para que) você irá usar o conceito de Events?

Os Events serão usados para interagir com a interface gráfica 
noticando ao usuário as etapas do sorteio e o resultado do mesmo.


# HARDHAT

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```
