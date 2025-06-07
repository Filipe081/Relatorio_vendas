CREATE OR REPLACE PROCEDURE GERAR_RELATORIO_ANALITICO_VENDAS (
    p_data_inicio            IN DATE,
    p_data_fim               IN DATE,
    p_id_produto             IN PRODUTOS.ID_PRODUTO%TYPE DEFAULT NULL,
    p_categoria_produto      IN PRODUTOS.CATEGORIA%TYPE DEFAULT NULL,
    p_id_cliente             IN CLIENTES.ID_CLIENTE%TYPE DEFAULT NULL,
    p_regiao_cliente         IN CLIENTES.REGIAO%TYPE DEFAULT NULL,
    p_canal_venda            IN VENDAS.CANAL_VENDA%TYPE DEFAULT NULL,
    p_resultado              OUT SYS_REFCURSOR
)
AS
BEGIN
    IF p_data_inicio > p_data_fim THEN
        RAISE_APPLICATION_ERROR(-20001, 'A data de início não pode ser maior que a data de fim.');
    END IF;

    OPEN p_resultado FOR
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
                ELSE ROUND((SUM(iv.QUANTIDADE * iv.PRECO_UNITARIO_VENDA) - SUM(iv.QUANTIDADE * p.PRECO_CUSTO)) /
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
        RAISE_APPLICATION_ERROR(-20002, 'Erro ao gerar relatório: ' || SQLERRM);
END;
/
