SET SERVEROUTPUT ON;
VAR v_cursor REFCURSOR;

BEGIN
  GERAR_RELATORIO_ANALITICO_VENDAS(
    p_data_inicio => TO_DATE('2025-01-01', 'YYYY-MM-DD'),
    p_data_fim => TO_DATE('2025-12-31', 'YYYY-MM-DD'),
    p_id_produto => NULL,
    p_categoria_produto => NULL,
    p_id_cliente => NULL,
    p_regiao_cliente => NULL,
    p_canal_venda => NULL,
    p_resultado => :v_cursor
  );
END;
/

PRINT v_cursor;
