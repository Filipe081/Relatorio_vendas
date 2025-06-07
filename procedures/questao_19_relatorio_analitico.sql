
-- CRIAÇÃO DAS TABELAS

CREATE TABLE PRODUTOS (
    ID_PRODUTO NUMBER PRIMARY KEY,
    NOME_PRODUTO VARCHAR2(100),
    CATEGORIA VARCHAR2(50),
    PRECO_CUSTO NUMBER(10,2)
);

CREATE TABLE CLIENTES (
    ID_CLIENTE NUMBER PRIMARY KEY,
    NOME_CLIENTE VARCHAR2(100),
    REGIAO VARCHAR2(50)
);

CREATE TABLE VENDAS (
    ID_VENDA NUMBER PRIMARY KEY,
    ID_CLIENTE NUMBER REFERENCES CLIENTES(ID_CLIENTE),
    DATA_VENDA DATE,
    CANAL_VENDA VARCHAR2(50)
);

CREATE TABLE ITENS_VENDA (
    ID_VENDA NUMBER REFERENCES VENDAS(ID_VENDA),
    ID_PRODUTO NUMBER REFERENCES PRODUTOS(ID_PRODUTO),
    QUANTIDADE NUMBER,
    PRECO_UNITARIO_VENDA NUMBER(10,2)
);

-- DADOS DE EXEMPLO

INSERT INTO PRODUTOS VALUES (1, 'Notebook', 'Eletrônicos', 2000);
INSERT INTO PRODUTOS VALUES (2, 'Mouse', 'Acessórios', 50);

INSERT INTO CLIENTES VALUES (1, 'João', 'Nordeste');
INSERT INTO CLIENTES VALUES (2, 'Maria', 'Sudeste');

INSERT INTO VENDAS VALUES (1, 1, TO_DATE('01/06/2025','DD/MM/YYYY'), 'Online');
INSERT INTO VENDAS VALUES (2, 2, TO_DATE('02/06/2025','DD/MM/YYYY'), 'Loja');

INSERT INTO ITENS_VENDA VALUES (1, 1, 2, 2500); -- Notebook
INSERT INTO ITENS_VENDA VALUES (1, 2, 3, 60);   -- Mouse
INSERT INTO ITENS_VENDA VALUES (2, 2, 5, 55);   -- Mouse

COMMIT;

-- STORED PROCEDURE

CREATE OR REPLACE PROCEDURE GERAR_RELATORIO_ANALITICO_VENDAS (
    p_data_inicio       IN DATE,
    p_data_fim          IN DATE,
    p_id_produto        IN PRODUTOS.ID_PRODUTO%TYPE DEFAULT NULL,
    p_categoria_produto IN PRODUTOS.CATEGORIA%TYPE DEFAULT NULL,
    p_id_cliente        IN CLIENTES.ID_CLIENTE%TYPE DEFAULT NULL,
    p_regiao_cliente    IN CLIENTES.REGIAO%TYPE DEFAULT NULL,
    p_canal_venda       IN VENDAS.CANAL_VENDA%TYPE DEFAULT NULL,
    p_cursor            OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT
            p.ID_PRODUTO,
            p.NOME_PRODUTO,
            p.CATEGORIA AS CATEGORIA_PRODUTO,
            SUM(iv.QUANTIDADE) AS QUANTIDADE_TOTAL_VENDIDA,
            SUM(iv.QUANTIDADE * iv.PRECO_UNITARIO_VENDA) AS RECEITA_BRUTA_TOTAL,
            SUM(iv.QUANTIDADE * p.PRECO_CUSTO) AS CUSTO_TOTAL_VENDIDO,
            SUM(iv.QUANTIDADE * iv.PRECO_UNITARIO_VENDA) - SUM(iv.QUANTIDADE * p.PRECO_CUSTO) AS LUCRO_BRUTO_TOTAL,
            CASE 
                WHEN SUM(iv.QUANTIDADE * iv.PRECO_UNITARIO_VENDA) = 0 THEN 0
                ELSE ROUND(
                    (SUM(iv.QUANTIDADE * iv.PRECO_UNITARIO_VENDA) - SUM(iv.QUANTIDADE * p.PRECO_CUSTO)) / 
                    SUM(iv.QUANTIDADE * iv.PRECO_UNITARIO_VENDA) * 100, 2)
            END AS MARGEM_LUCRO_BRUTO_PERCENTUAL,
            CASE 
                WHEN SUM(iv.QUANTIDADE) = 0 THEN 0
                ELSE ROUND(SUM(iv.QUANTIDADE * iv.PRECO_UNITARIO_VENDA) / SUM(iv.QUANTIDADE), 2)
            END AS PRECO_MEDIO_VENDA_UNITARIO,
            COUNT(DISTINCT v.ID_VENDA) AS NUM_VENDAS_DISTINTAS_PRODUTO
        FROM PRODUTOS p
        JOIN ITENS_VENDA iv ON p.ID_PRODUTO = iv.ID_PRODUTO
        JOIN VENDAS v ON iv.ID_VENDA = v.ID_VENDA
        JOIN CLIENTES c ON v.ID_CLIENTE = c.ID_CLIENTE
        WHERE v.DATA_VENDA BETWEEN p_data_inicio AND p_data_fim
            AND (p_id_produto IS NULL OR p.ID_PRODUTO = p_id_produto)
            AND (p_categoria_produto IS NULL OR p.CATEGORIA = p_categoria_produto)
            AND (p_id_cliente IS NULL OR c.ID_CLIENTE = p_id_cliente)
            AND (p_regiao_cliente IS NULL OR c.REGIAO = p_regiao_cliente)
            AND (p_canal_venda IS NULL OR v.CANAL_VENDA = p_canal_venda)
        GROUP BY p.ID_PRODUTO, p.NOME_PRODUTO, p.CATEGORIA;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Erro ao gerar relatório: ' || SQLERRM);
END;
/

-- BLOCO DE TESTE

DECLARE
    v_cursor SYS_REFCURSOR;
    v_id NUMBER;
    v_nome VARCHAR2(100);
    v_categoria VARCHAR2(50);
    v_qtd NUMBER;
    v_receita NUMBER;
    v_custo NUMBER;
    v_lucro NUMBER;
    v_margem NUMBER;
    v_preco_medio NUMBER;
    v_num_vendas NUMBER;
BEGIN
    GERAR_RELATORIO_ANALITICO_VENDAS(
        p_data_inicio => TO_DATE('01/06/2025','DD/MM/YYYY'),
        p_data_fim    => TO_DATE('30/06/2025','DD/MM/YYYY'),
        p_cursor      => v_cursor
    );

    LOOP
        FETCH v_cursor INTO v_id, v_nome, v_categoria, v_qtd, v_receita, v_custo, v_lucro, v_margem, v_preco_medio, v_num_vendas;
        EXIT WHEN v_cursor%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('Produto: ' || v_nome || ', Receita: ' || v_receita || ', Lucro: ' || v_lucro);
    END LOOP;

    CLOSE v_cursor;
END;
/
