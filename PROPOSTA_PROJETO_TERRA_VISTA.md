# PROPOSTA DE PROJETO: ECOSSISTEMA DIGITAL TERRA VISTA

**Subtítulo:** Preservação de Memória, Transparência Agroecológica e Inclusão Digital Rural.
**Duração do Projeto:** 12 Meses.
**Status:** Documento Executivo para Captação de Recursos.

---

## 1. INTRODUÇÃO E IMPORTÂNCIA
A maioria dos assentamentos e comunidades rurais sustentáveis possui uma riqueza imensa de conhecimento (história, técnicas de plantio, biodiversidade) que se perde por falta de registro ou fica restrita a poucos. 

**O projeto Terra Vista resolve três problemas críticos:**
1.  **O Abismo Digital:** Traz tecnologia de ponta para o campo, capacitando jovens moradores.
2.  **A Invisibilidade da Produção:** Permite que o consumidor final veja, através de fotos e dados georreferenciados, a origem ética de seu alimento.
3.  **A Perda de Memória:** Registra permanentemente a história da comunidade, transformando o assentamento em um polo de turismo pedagógico.

---

## 2. IMPACTO SOCIAL E OBJETIVOS
*   **Empoderamento Juvenil:** Jovens saem da posição de consumidores de tecnologia para gestores de tecnologia, reduzindo o êxodo rural.
*   **Valorização da Agroecologia:** Ao escanear um QR Code em uma horta, o visitante entende o valor do manejo orgânico, aumentando a disposição de compra e o preço justo.
*   **Educação Patrimonial:** Escolas da região podem usar o app como uma ferramenta de aula ao ar livre, reconectando as novas gerações com a terra.
*   **Sustentabilidade Econômica:** Atrai visitantes e parceiros, gerando novas fontes de renda para a comunidade através do turismo consciente.

## 3. TECNOLOGIAS UTILIZADAS (TECH STACK)
A escolha das tecnologias baseia-se na eficiência de custo, velocidade de desenvolvimento e robustez para uso em condições variadas.

*   **Frontend (Aplicativo e Painel):** **Flutter**, framework do Google que permite criar uma experiência premium idêntica em iPhones, celulares Android e navegadores Web com um único código.
*   **Backend e Banco de Dados:** **Firebase Firestore (NoSQL)**, garantindo que os dados sejam sincronizados em tempo real e permitindo o funcionamento **Offline First** (o app funciona mesmo sem internet no momento da coleta).
*   **Armazenamento de Mídia:** **Firebase Cloud Storage**, infraestrutura de alta performance para hospedar as fotos profissionais e vídeos do projeto.
*   **Segurança e Autenticação:** **Firebase Auth**, protegendo o acesso administrativo com criptografia de ponta a ponta.
*   **Infraestrutura de Rede:** **Starlink**, tecnologia de internet via satélite de baixa latência, essencial para garantir que a base operacional no assentamento tenha conexão estável.
*   **Geolocalização:** Integração nativa com **GPS** para mapeamento preciso de lotes e trilhas.

---

## 4. FUNCIONAMENTO DETALHADO

### O Ciclo de Vida da Informação:
1.  **Captação:** O Fotógrafo e o Mobilizador coletam imagens profissionais e histórias reais de pontos de interesse (agroflorestas, escolas, centros comunitários).
2.  **Curadoria:** O Designer e os Bolsistas organizam esse material em formatos digitais atraentes.
3.  **Publicação:** Através do Painel Administrativo Web, o conteúdo é cadastrado com fotos de alta qualidade e coordenadas GPS precisas.
4.  **Sinalização:** O sistema gera automaticamente um QR Code exclusivo, que é impresso em placas físicas resistentes e instaladas no local físico.
5.  **Acesso:** O Visitante aponta a câmera do celular ou usa o scanner do app Terra Vista para acessar o conteúdo completo, mesmo em áreas com conexão limitada (via sistema de cache inteligente).

---

## 5. CRONOGRAMA DE EXECUÇÃO (ROADMAP 12 MESES)

| Fase | Período | Atividades Principais |
| :--- | :--- | :--- |
| **Fase 1: Estruturação** | Mês 01 - 02 | Contratação da equipe, compra de hardware, instalação da internet Starlink e configuração do core tecnológico em nuvem. |
| **Fase 2: Desenvolvimento** | Mês 03 - 04 | Construção do Aplicativo (Flutter) e Painel Web. Início da coleta de fotos profissionais (banco de imagens inicial). |
| **Fase 3: Engajamento** | Mês 05 - 06 | Oficinas comunitárias para coleta de memória oral e treinamento intensivo dos bolsistas locais. |
| **Fase 4: Materialização** | Mês 07 - 08 | Impressão e instalação das placas físicas de QR Code. Lançamento da versão de teste (Beta). |
| **Fase 5: Expansão** | Mês 09 - 10 | Refinamento de recursos de geolocalização e inclusão de conteúdos em vídeo para os pontos principais. |
| **Fase 6: Autonomia** | Mês 11 - 12 | Evento de lançamento oficial, entrega de manuais de manutenção e transferência integral da gestão para a comunidade. |

---

## 6. ORÇAMENTO DETALHADO

### 5.1 Recursos Humanos (RH Anual)
| Cargo | Vaga | Custo Mensal (R$) | Total 12 Meses (R$) |
| :--- | :--- | :--- | :--- |
| Coordenador Geral | 01 | R$ 6.500,00 | R$ 78.000,00 |
| Desenvolvedor Fullstack Flutter | 01 | R$ 9.000,00 | R$ 108.000,00 |
| Fotógrafo e Editor de Mídia | 01 | R$ 5.000,00 | R$ 60.000,00 |
| Designer UI/UX & Comunicação | 01 | R$ 4.500,00 | R$ 54.000,00 |
| Mobilizadores Comunitários | 02 | R$ 3.000,00 | R$ 72.000,00 |
| Bolsistas da Comunidade | 03 | R$ 1.200,00 | R$ 43.200,00 |
| **Subtotal RH** | | | **R$ 415.200,00** |

### 5.2 Hardware e Equipamentos
| Item | Quantidade | Valor Unitário (R$) | Total (R$) |
| :--- | :--- | :--- | :--- |
| Câmera Profissional (Mirrorless Full Frame) | 1 | R$ 8.500,00 | R$ 8.500,00 |
| Notebook de Edição (Alta Performance) | 1 | R$ 7.200,00 | R$ 7.200,00 |
| Notebook de Desenvolvimento (Dev) | 1 | R$ 6.500,00 | R$ 6.500,00 |
| Notebook de Gestão e Escrita | 1 | R$ 3.800,00 | R$ 3.800,00 |
| Tablets de Campo (Rugged/Resistentes) | 4 | R$ 2.200,00 | R$ 8.800,00 |
| Kit Instalação Starlink (Antena/Roteador) | 1 | R$ 2.500,00 | R$ 2.500,00 |
| **Subtotal Hardware** | | | **R$ 37.300,00** |

### 5.3 Conectividade e Nuvem (Mensalidades)
| Item | Descrição | Mensal (R$) | Total 12 Meses (R$) |
| :--- | :--- | :--- | :--- |
| Internet Starlink (Plano Rural) | Alta velocidade p/ assentamento | R$ 250,00 | R$ 3.000,00 |
| Firebase Storage (Fotos HD) | Armazenamento seguro de nuvem | R$ 180,00 | R$ 2.160,00 |
| Firebase Database & Hosting | Banco de dados e site administrativo | R$ 120,00 | R$ 1.440,00 |
| Monitoramento e Segurança | Backups e integridade de dados | R$ 50,00 | R$ 600,00 |
| **Subtotal Conectividade** | | | **R$ 7.200,00** |

---

## 7. RESUMO DO INVESTIMENTO TOTAL

*   **Recursos Humanos (RH):** R$ 415.200,00
*   **Equipamentos (Hardware):** R$ 37.300,00
*   **Conectividade e Nuvem:** R$ 7.200,00
*   **Logística e Sinalização Física:** R$ 18.000,00 (Placas, deslocamentos e eventos)

### **INVESTIMENTO TOTAL:** **R$ 477.700,00**

---

## 8. CONCLUSÃO E SUSTENTABILIDADE
Ao final de 12 meses, o projeto Terra Vista deixará um legado duplo: uma ferramenta tecnológica de ponta e uma comunidade capacitada para geri-la. Este investimento cria uma vitrine digital para a agroecologia brasileira, servindo de modelo replicável para outros assentamentos e fortalecendo a economia local através da inovação e da memória.
