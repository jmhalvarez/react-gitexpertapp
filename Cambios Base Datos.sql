SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO



ALTER        PROCEDURE dbo.InsertarActaCumplidoresMes
	(
	@mesAnho datetime
	)
	
AS
	/* SET NOCOUNT ON */ 	
	DELETE FROM ActaConcil_Cumplidores WHERE (mesAnho = @mesAnho)
	
	 INSERT INTO ActaConcil_Cumplidores([Plan], Id_Entidad, Nombre, [Real], mesAnho, Id_ActaConc)	
	 --Insertar los de las CCS 
	   SELECT        PlanProdAcomTrim.Litros AS [Plan], Pto_Recogida.Id_Entidad, PlanProdAcomTrim.Id_Productor, RealProdAcomTrim.Litros AS Real, PlanProdAcomTrim.Fecha, 
	                            ActaConciliacion.Id
	   FROM            PlanProdAcomTrim INNER JOIN
	                            RealProdAcomTrim ON PlanProdAcomTrim.Id_Productor = RealProdAcomTrim.Id_Productor AND PlanProdAcomTrim.Fecha = RealProdAcomTrim.Fecha AND 
	                            PlanProdAcomTrim.Id_Tipo_Leche = RealProdAcomTrim.Id_Tipo_Leche AND PlanProdAcomTrim.Litros <= RealProdAcomTrim.Litros INNER JOIN
	                            Pto_Recogida ON RealProdAcomTrim.Id_Productor = Pto_Recogida.Codigo INNER JOIN
	                            Entidad ON Pto_Recogida.Id_Entidad = Entidad.Id_Entidad INNER JOIN
	                            ActaConciliacion ON RealProdAcomTrim.Fecha = ActaConciliacion.mesAnho AND Entidad.Id_Entidad = ActaConciliacion.IdEntidad
	   WHERE        (PlanProdAcomTrim.Id_Tipo_Leche = 1) AND (RealProdAcomTrim.Litros > 0) AND (PlanProdAcomTrim.Fecha = @mesAnho) AND (PlanProdAcomTrim.Total >= 520) AND 
	                            (Pto_Recogida.Indicaciones = 1)/* AND (Entidad.Id_Clasificacion = 3)*/
	                          
	 union
	 --Insertar el resto
	 SELECT        PlanAcomTrim.Litros AS [Plan], FunctionActaConcTrim_1.IdEntidad, FunctionActaConcTrim_1.Entidad, FunctionActaConcTrim_1.LtsVaca, PlanAcomTrim.Fecha, 
	                          FunctionActaConcTrim_1.Id
	 FROM            PlanAcomTrim INNER JOIN
	                          dbo.FunctionActaConcTrim(@mesAnho) AS FunctionActaConcTrim_1 ON PlanAcomTrim.Id_Entidad = FunctionActaConcTrim_1.IdEntidad AND 
	                          PlanAcomTrim.Litros <= FunctionActaConcTrim_1.LtsVaca INNER JOIN
	                          Entidad ON PlanAcomTrim.Id_Entidad = Entidad.Id_Entidad
	 WHERE        (PlanAcomTrim.Fecha = @mesAnho) AND (PlanAcomTrim.Id_Tipo_Leche = 1) AND (PlanAcomTrim.Total >= 520) AND (NOT (Entidad.Id_Clasificacion = 3))	
	 
	 	                          
	 --Insertar los de comercio
	 union 
	 SELECT        0 AS [Plan], Pto_Recogida.Id_Entidad, RealProdAcomTrim.Id_Productor, RealProdAcomTrim.Litros AS Real, RealProdAcomTrim.Fecha, ActaConciliacion.Id
	 FROM            RealProdAcomTrim INNER JOIN
	                          Pto_Recogida ON RealProdAcomTrim.Id_Productor = Pto_Recogida.Codigo INNER JOIN
	                          ActaConciliacion ON RealProdAcomTrim.Fecha = ActaConciliacion.mesAnho AND Pto_Recogida.Id_Entidad = ActaConciliacion.IdEntidad
	 WHERE        (RealProdAcomTrim.Litros > 0) AND (Pto_Recogida.Indicaciones = 1) AND (RealProdAcomTrim.Id_Tipo_Leche = 1) AND (RealProdAcomTrim.Fecha = @mesAnho) AND 
	                          (Pto_Recogida.Comercio = 1)
	                          	                          
	 --Actualizar Importe MLC en Acta de conciliación
	 UPDATE       ActaConciliacion
	 SET                ImporteMLC = a.ImporteMLC
	 FROM            ActaConciliacion INNER JOIN
	                              (SELECT        ActaConcil_Cumplidores.Id_ActaConc, SUM((ActaConcil_Cumplidores.Real - ActaConcil_Cumplidores.[Plan]) * Mes.PrecioDivisa) AS ImporteMLC
	                                FROM            ActaConcil_Cumplidores INNER JOIN
	                                                          Mes ON ActaConcil_Cumplidores.mesAnho = Mes.Mes_Anho
	                                WHERE        (ActaConcil_Cumplidores.mesAnho = @mesAnho)
	                                GROUP BY ActaConcil_Cumplidores.Id_ActaConc) AS a ON ActaConciliacion.Id = a.Id_ActaConc
	
	RETURN







GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO



SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO



ALTER      PROCEDURE dbo.InsertarActaCumplidores
	(
	@IdActaConc int,
	@mesAnho datetime,
	@idEntidad int
	)
	
AS
	/* SET NOCOUNT ON */ 	
	/*	if (SELECT        MIN(Id_Clasificacion) AS clasificacion
	    FROM            Entidad
	    WHERE        (Id_Entidad = @IdEntidad)) = 3	
	 begin */
	 --Insertar los de las CCS
	 INSERT INTO ActaConcil_Cumplidores([Plan], Id_Entidad, Nombre, [Real], mesAnho, Id_ActaConc)	 
	 SELECT        PlanProdAcomTrim.Litros AS [Plan], Pto_Recogida.Id_Entidad, PlanProdAcomTrim.Id_Productor, RealProdAcomTrim.Litros AS Real, PlanProdAcomTrim.Fecha, 
	                          @IdActaConc AS IdActaConc
	 FROM            PlanProdAcomTrim INNER JOIN
	                          RealProdAcomTrim ON PlanProdAcomTrim.Id_Productor = RealProdAcomTrim.Id_Productor AND PlanProdAcomTrim.Fecha = RealProdAcomTrim.Fecha AND 
	                          PlanProdAcomTrim.Id_Tipo_Leche = RealProdAcomTrim.Id_Tipo_Leche AND PlanProdAcomTrim.Litros <= RealProdAcomTrim.Litros INNER JOIN
	                          Pto_Recogida ON RealProdAcomTrim.Id_Productor = Pto_Recogida.Codigo
	 WHERE        (PlanProdAcomTrim.Id_Tipo_Leche = 1) AND (RealProdAcomTrim.Litros > 0) AND (PlanProdAcomTrim.Fecha = @mesAnho) AND 
	                          (Pto_Recogida.Id_Entidad = @IdEntidad) AND (PlanProdAcomTrim.Total >= 520) AND (Pto_Recogida.Indicaciones = 1) 
	/* end
	 else
	 begin */
	 --Insertar el resto
	 INSERT INTO ActaConcil_Cumplidores
	                          ([Plan], Id_Entidad, Nombre, [Real], mesAnho, Id_ActaConc)
	 SELECT        PlanAcomTrim.Litros AS [Plan], FunctionActaConcTrim_1.IdEntidad, FunctionActaConcTrim_1.Entidad, FunctionActaConcTrim_1.LtsVaca, PlanAcomTrim.Fecha, 
	                          FunctionActaConcTrim_1.Id
	 FROM            PlanAcomTrim INNER JOIN
	                          dbo.FunctionActaConcTrim(@mesAnho) AS FunctionActaConcTrim_1 ON PlanAcomTrim.Id_Entidad = FunctionActaConcTrim_1.IdEntidad AND 
	                          PlanAcomTrim.Litros <= FunctionActaConcTrim_1.LtsVaca
	 WHERE        (PlanAcomTrim.Fecha = @mesAnho) AND (PlanAcomTrim.Id_Tipo_Leche = 1) AND (PlanAcomTrim.Total >= 520) AND 
	                          (FunctionActaConcTrim_1.IdEntidad = @idEntidad)	 
	-- end
	 
	 --Insertar los de comercio
	 INSERT INTO ActaConcil_Cumplidores([Plan], Id_Entidad, Nombre, [Real], mesAnho, Id_ActaConc)	 
	 SELECT        0 AS [Plan], Pto_Recogida.Id_Entidad, RealProdAcomTrim.Id_Productor, RealProdAcomTrim.Litros AS Real, RealProdAcomTrim.Fecha, 
	                          @IdActaConc AS IdActaConc
	 FROM            RealProdAcomTrim INNER JOIN
	                          Pto_Recogida ON RealProdAcomTrim.Id_Productor = Pto_Recogida.Codigo
	 WHERE        (RealProdAcomTrim.Litros > 0) AND (Pto_Recogida.Id_Entidad = @IdEntidad) AND (Pto_Recogida.Indicaciones = 1) AND (RealProdAcomTrim.Id_Tipo_Leche = 1) 
	                          AND (RealProdAcomTrim.Fecha = @mesAnho) AND (Pto_Recogida.Comercio = 1) 
	 
	  --Actualizar Importe MLC en Acta de conciliación
	 UPDATE       ActaConciliacion
	 SET                ImporteMLC = a.ImporteMLC
	 FROM            ActaConciliacion INNER JOIN
	                              (SELECT        ActaConcil_Cumplidores.Id_ActaConc, SUM((ActaConcil_Cumplidores.Real - ActaConcil_Cumplidores.[Plan]) * Mes.PrecioDivisa) AS ImporteMLC
	                                FROM            ActaConcil_Cumplidores INNER JOIN
	                                                          Mes ON ActaConcil_Cumplidores.mesAnho = Mes.Mes_Anho
	                                WHERE        (ActaConcil_Cumplidores.mesAnho = @mesAnho)
	                                GROUP BY ActaConcil_Cumplidores.Id_ActaConc) AS a ON ActaConciliacion.Id = a.Id_ActaConc
	                                where actaConciliacion.id = @IdActaConc
	                                
	RETURN






GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO





ALTER       PROCEDURE dbo.InsertarActaIncumplidoresMes
	(
	@mesAnho datetime
	)
	
AS
	/* SET NOCOUNT ON */ 	
	DELETE FROM ActaConcil_Incumplidores WHERE (mesAnho = @mesAnho)
	
	 INSERT INTO ActaConcil_Incumplidores([Plan], Id_Entidad, Nombre, [Real], mesAnho, Id_ActaConc)	
	 --Insertar los de las CCS 
	 SELECT        SUM([Plan]) AS [Plan], Id_Entidad, Id_Productor, SUM(Real) AS Real, Fecha, Id
	 FROM            (SELECT        SUM(PlanProdAcomTrim.Litros) AS [Plan], Pto_Recogida.Id_Entidad, PlanProdAcomTrim.Id_Productor, 0 AS Real, PlanProdAcomTrim.Fecha, 
	                                                     ActaConciliacion.Id
	                           FROM            PlanProdAcomTrim INNER JOIN
	                                                     Pto_Recogida ON PlanProdAcomTrim.Id_Productor = Pto_Recogida.Codigo INNER JOIN
	                                                     Entidad ON Pto_Recogida.Id_Entidad = Entidad.Id_Entidad INNER JOIN
	                                                     ActaConciliacion ON Entidad.Id_Entidad = ActaConciliacion.IdEntidad AND PlanProdAcomTrim.Fecha = ActaConciliacion.mesAnho
	                          /* WHERE        (Entidad.Id_Clasificacion = 3) */
	                           GROUP BY Pto_Recogida.Id_Entidad, PlanProdAcomTrim.Id_Productor, PlanProdAcomTrim.Fecha, ActaConciliacion.Id
	                           HAVING         (PlanProdAcomTrim.Fecha = @mesAnho) AND (SUM(PlanProdAcomTrim.Litros) > 0)
	                           UNION
	                           SELECT        0 AS [Plan], Pto_Recogida.Id_Entidad, RealProdAcomTrim.Id_Productor, SUM(RealProdAcomTrim.Litros) AS Real, RealProdAcomTrim.Fecha, 
	                                                    ActaConciliacion.Id
	                           FROM            RealProdAcomTrim INNER JOIN
	                                                    Pto_Recogida ON RealProdAcomTrim.Id_Productor = Pto_Recogida.Codigo INNER JOIN
	                                                    Entidad ON Pto_Recogida.Id_Entidad = Entidad.Id_Entidad INNER JOIN
	                                                    ActaConciliacion ON Entidad.Id_Entidad = ActaConciliacion.IdEntidad AND RealProdAcomTrim.Fecha = ActaConciliacion.mesAnho
	                          /* WHERE        (Entidad.Id_Clasificacion = 3) */
	                           GROUP BY Pto_Recogida.Id_Entidad, RealProdAcomTrim.Id_Productor, RealProdAcomTrim.Fecha, ActaConciliacion.Id
	                           HAVING        (RealProdAcomTrim.Fecha = @mesAnho) AND (SUM(RealProdAcomTrim.Litros) > 0)) AS unidos
	 GROUP BY Id_Entidad, Id_Productor, Fecha, Id
	 HAVING        (SUM([Plan]) > SUM(Real))
	 
	 union
	 --Insertar el resto
	 SELECT        SUM(PlanAcomTrim.Litros) AS [Plan], FunctionActaConcTrim_1.IdEntidad, FunctionActaConcTrim_1.Entidad, 
	                          FunctionActaConcTrim_1.LtsVaca + FunctionActaConcTrim_1.LtsCabra + FunctionActaConcTrim_1.LtsBufala AS Real, PlanAcomTrim.Fecha, 
	                          FunctionActaConcTrim_1.Id
	 FROM            dbo.FunctionActaConcTrim(@mesAnho) AS FunctionActaConcTrim_1 INNER JOIN
	                          PlanAcomTrim ON FunctionActaConcTrim_1.IdEntidad = PlanAcomTrim.Id_Entidad INNER JOIN
	                          Entidad ON PlanAcomTrim.Id_Entidad = Entidad.Id_Entidad
	 WHERE        (Entidad.Id_Clasificacion <> 3) AND (PlanAcomTrim.Fecha = @mesAnho)
	 GROUP BY FunctionActaConcTrim_1.IdEntidad, FunctionActaConcTrim_1.Entidad, PlanAcomTrim.Fecha, FunctionActaConcTrim_1.Id, FunctionActaConcTrim_1.LtsVaca, 
	                          FunctionActaConcTrim_1.LtsCabra, FunctionActaConcTrim_1.LtsBufala
	 HAVING        (SUM(PlanAcomTrim.Litros) > FunctionActaConcTrim_1.LtsVaca + FunctionActaConcTrim_1.LtsCabra + FunctionActaConcTrim_1.LtsBufala)
	
	RETURN



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO



ALTER    PROCEDURE dbo.InsertarActaIncumplidores
	(
	@IdActaConc int,
	@mesAnho datetime,
	@idEntidad int
	)
AS
	/* SET NOCOUNT ON */ 	
	/*	if (SELECT        MIN(Id_Clasificacion) AS clasificacion
	    FROM            Entidad
	    WHERE        (Id_Entidad = @IdEntidad)) = 3	
	 begin */
	 --Insertar los de las CCS
	 INSERT INTO ActaConcil_Incumplidores([Plan], Id_Entidad, Nombre, [Real], mesAnho, Id_ActaConc)	 
	 SELECT        SUM([Plan]) AS [Plan], Id_Entidad, Id_Productor, SUM(Real) AS Real, Fecha, Id
	 FROM            (SELECT        SUM(PlanProdAcomTrim.Litros) AS [Plan], Pto_Recogida.Id_Entidad, PlanProdAcomTrim.Id_Productor, 0 AS Real, PlanProdAcomTrim.Fecha, 
	                                                     ActaConciliacion.Id
	                           FROM            PlanProdAcomTrim INNER JOIN
	                                                     Pto_Recogida ON PlanProdAcomTrim.Id_Productor = Pto_Recogida.Codigo INNER JOIN
	                                                     Entidad ON Pto_Recogida.Id_Entidad = Entidad.Id_Entidad INNER JOIN
	                                                     ActaConciliacion ON Entidad.Id_Entidad = ActaConciliacion.IdEntidad AND PlanProdAcomTrim.Fecha = ActaConciliacion.mesAnho
	                          /* WHERE        (Entidad.Id_Clasificacion = 3)*/
	                           GROUP BY Pto_Recogida.Id_Entidad, PlanProdAcomTrim.Id_Productor, PlanProdAcomTrim.Fecha, ActaConciliacion.Id
	                           HAVING         (PlanProdAcomTrim.Fecha = @mesAnho) AND (SUM(PlanProdAcomTrim.Litros) > 0) AND (Pto_Recogida.Id_Entidad = @IdEntidad)
	                           UNION
	                           SELECT        0 AS [Plan], Pto_Recogida.Id_Entidad, RealProdAcomTrim.Id_Productor, SUM(RealProdAcomTrim.Litros) AS Real, RealProdAcomTrim.Fecha, 
	                                                    ActaConciliacion.Id
	                           FROM            RealProdAcomTrim INNER JOIN
	                                                    Pto_Recogida ON RealProdAcomTrim.Id_Productor = Pto_Recogida.Codigo INNER JOIN
	                                                    Entidad ON Pto_Recogida.Id_Entidad = Entidad.Id_Entidad INNER JOIN
	                                                    ActaConciliacion ON Entidad.Id_Entidad = ActaConciliacion.IdEntidad AND RealProdAcomTrim.Fecha = ActaConciliacion.mesAnho
	                          /* WHERE        (Entidad.Id_Clasificacion = 3)*/
	                           GROUP BY Pto_Recogida.Id_Entidad, RealProdAcomTrim.Id_Productor, RealProdAcomTrim.Fecha, ActaConciliacion.Id
	                           HAVING        (RealProdAcomTrim.Fecha = @mesAnho) AND (SUM(RealProdAcomTrim.Litros) > 0) AND (Pto_Recogida.Id_Entidad = @IdEntidad)) AS unidos
	 GROUP BY Id_Entidad, Id_Productor, Fecha, Id
	 HAVING        (SUM([Plan]) > SUM(Real))
	/* end
	 else
	 begin */
	 --Insertar el resto
	 INSERT INTO ActaConcil_Incumplidores
	                          ([Plan], Id_Entidad, Nombre, Real, mesAnho, Id_ActaConc)
	 SELECT        SUM(PlanAcomTrim.Litros) AS [Plan], FunctionActaConcTrim_1.IdEntidad, FunctionActaConcTrim_1.Entidad, 
	                          FunctionActaConcTrim_1.LtsVaca + FunctionActaConcTrim_1.LtsCabra + FunctionActaConcTrim_1.LtsBufala AS Real, PlanAcomTrim.Fecha, FunctionActaConcTrim_1.Id
	 FROM            dbo.FunctionActaConcTrim(@mesAnho) AS FunctionActaConcTrim_1 INNER JOIN
	                          PlanAcomTrim ON FunctionActaConcTrim_1.IdEntidad = PlanAcomTrim.Id_Entidad
	 WHERE        (PlanAcomTrim.Fecha = @mesAnho)
	 GROUP BY FunctionActaConcTrim_1.IdEntidad, FunctionActaConcTrim_1.Entidad, PlanAcomTrim.Fecha, FunctionActaConcTrim_1.Id, FunctionActaConcTrim_1.LtsVaca, 
	                          FunctionActaConcTrim_1.LtsCabra, FunctionActaConcTrim_1.LtsBufala
	 HAVING        (FunctionActaConcTrim_1.Id = @IdActaConc) AND 
	                          (FunctionActaConcTrim_1.LtsVaca + FunctionActaConcTrim_1.LtsCabra + FunctionActaConcTrim_1.LtsBufala < SUM(PlanAcomTrim.Litros))
	-- end
	RETURN



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


Alter Table [Vale de Compra] DROP CONSTRAINT [DF_Vale de Compra_LecheFria]
GO

Alter Table [Vale de Compra] DROP COLUMN [LecheFria]
GO

Alter Table [Vale de Compra] Add [LecheFria] bit NOT NULL CONSTRAINT [DF_Vale de Compra_LecheFria] DEFAULT (1)
go


SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO



ALTER   FUNCTION dbo.FunctionDecenaProduccion 
	(
	@Mes_Anho datetime --,
	--@tipoLeche int
	)
RETURNS  @DecenaProd TABLE (TipoLeche varchar(50),IdEntidad int,Entidad varchar(50), Fecha datetime,Litros int,Importe dec(8,2),Precio dec(5,3),Municipio varchar(50),Clasificacion varchar(50),Codigo varchar(50), Decena int default 1, Sancionada int, LecheFria bit default 1, Sector varchar(10), Ruta varchar(50), Empresa varchar(50))
AS
	BEGIN
	 INSERT INTO @DecenaProd(TipoLeche,IdEntidad ,Entidad , Fecha ,Litros,Importe,Precio ,Municipio,Clasificacion,Codigo,Sancionada,Sector,Ruta,Empresa,LecheFria)				
	 SELECT        [Tipo de Animal].Nombre AS TipoLeche, Entidad.Id_Entidad, Entidad.Nombre AS Entidad, [Registro Diario].Fecha, SUM([Vale de Compra].Litros) AS Litros, 
	                          SUM([Vale de Compra].Litros * [Vale de Compra].Precio) AS Importe, SUM([Vale de Compra].Litros * [Vale de Compra].Precio) / SUM([Vale de Compra].Litros) AS Precio,
	                           Municipio.Nombre AS Municipio, Clasificacion.Clasificacion, Pto_Recogida.Codigo, SUM([Vale de Compra].Sancionados) AS Sancionados, Clasificacion.Sector, 
	                          Ruta.Nombre AS Ruta, Empresa.Nombre AS Empresa, [Vale de Compra].LecheFria
	 FROM            Municipio INNER JOIN
	                          Entidad ON Municipio.Id_Municipio = Entidad.Id_Municipio INNER JOIN
	                          Clasificacion ON Entidad.Id_Clasificacion = Clasificacion.Id_Clasificacion INNER JOIN
	                          [Registro Diario] INNER JOIN
	                          [Vale de Compra] ON [Registro Diario].Id_Diario = [Vale de Compra].Id_Diario INNER JOIN
	                          Pto_Recogida ON [Vale de Compra].Codigo = Pto_Recogida.Codigo ON Entidad.Id_Entidad = Pto_Recogida.Id_Entidad INNER JOIN
	                          Ruta ON Pto_Recogida.IdRuta = Ruta.Id INNER JOIN
	                          Empresa ON Entidad.IdEmpresa = Empresa.Id_Empresa INNER JOIN
	                          [Tipo de Animal] ON [Vale de Compra].TipoLeche = [Tipo de Animal].Id_Animal
	 WHERE        ([Registro Diario].Mes_Anho = @Mes_Anho)
	 GROUP BY [Vale de Compra].TipoLeche, Entidad.Id_Entidad, [Registro Diario].Fecha, Entidad.Nombre, Municipio.Nombre, Clasificacion.Clasificacion, Pto_Recogida.Codigo, 
	                          Clasificacion.Sector, Ruta.Nombre, Empresa.Nombre, [Tipo de Animal].Nombre, [Vale de Compra].LecheFria
	UNION
	SELECT        [Tipo de Animal].Nombre AS TipoLeche, Entidad.Id_Entidad, Entidad.Nombre AS Entidad, LecheDejadaAcopiar.Fecha, SUM(LecheDejadaAcopiar.Litros) AS Litros, 
	                         SUM(LecheDejadaAcopiar.Litros * LecheDejadaAcopiar.Precio) AS Importe, SUM(LecheDejadaAcopiar.Litros * LecheDejadaAcopiar.Precio) 
	                         / SUM(LecheDejadaAcopiar.Litros) AS Precio, Municipio.Nombre AS Municipio, Clasificacion.Clasificacion, Pto_Recogida.Codigo, 
	                         SUM(LecheDejadaAcopiar.Sancionada) AS Sancionada, Clasificacion.Sector, Ruta.Nombre AS Ruta, Empresa.Nombre AS Empresa, 1 as fria
	FROM            LecheDejadaAcopiar INNER JOIN
	                         Municipio INNER JOIN
	                         Entidad ON Municipio.Id_Municipio = Entidad.Id_Municipio INNER JOIN
	                         Clasificacion ON Entidad.Id_Clasificacion = Clasificacion.Id_Clasificacion INNER JOIN
	                         Pto_Recogida ON Entidad.Id_Entidad = Pto_Recogida.Id_Entidad ON LecheDejadaAcopiar.Codigo = Pto_Recogida.Codigo INNER JOIN
	                         Ruta ON Pto_Recogida.IdRuta = Ruta.Id INNER JOIN
	                         Empresa ON Entidad.IdEmpresa = Empresa.Id_Empresa INNER JOIN
	                         [Tipo de Animal] ON LecheDejadaAcopiar.TipoLeche = [Tipo de Animal].Id_Animal
	WHERE        (LecheDejadaAcopiar.MesAnho = @Mes_Anho)
	GROUP BY LecheDejadaAcopiar.TipoLeche, Entidad.Id_Entidad, Entidad.Nombre, Municipio.Nombre, Clasificacion.Clasificacion, Pto_Recogida.Codigo, 
	                         LecheDejadaAcopiar.Codigo, LecheDejadaAcopiar.Fecha, Clasificacion.Sector, Ruta.Nombre, Empresa.Nombre, [Tipo de Animal].Nombre
 
UPDATE @DecenaProd       
		 SET Decena = 2
		 from @DecenaProd rep
		 where DATEPART(DAY,rep.Fecha) between 11 and 20
		 
UPDATE @DecenaProd       
		 SET Decena = 3
		 from @DecenaProd rep
		 where DATEPART(DAY,rep.Fecha) > 20 
		 		 
	/*	UPDATE       @DecenaProd
		SET                LecheFria = rep.litros
		FROM            @DecenaProd AS rep INNER JOIN
		                             (SELECT        [Vale de Compra].Codigo, [Vale de Compra].Litros, [Registro Diario].Fecha, [Vale de Compra].TipoLeche
		                               FROM            [Vale de Compra] INNER JOIN
		                                                         [Registro Diario] ON [Vale de Compra].Id_Diario = [Registro Diario].Id_Diario
		                               WHERE        ([Registro Diario].Mes_Anho = @Mes_Anho) AND ([Vale de Compra].LecheFria = 1)) AS pto ON rep.Codigo = pto.Codigo AND rep.Fecha = pto.Fecha AND 
		                         rep.TipoLeche = pto.TipoLeche*/
	RETURN
	END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO



ALTER   PROCEDURE dbo.InsertarActaConciliacion 
	(
	@mesAnho datetime,
	@IdEntidad int,
	@Empresa bit
	)
AS
	 SET NOCOUNT ON 
	 --precios de acarreo
	 declare @PrecioMin decimal(6,3),@PrecioMed decimal(6,3), @PrecioMax decimal(6,3),@PrecioFrio dec(4,2),@LtsVaca int ,@PrecVaca dec(8,6),
	 @LtsCabra int, @PrecCabra dec(8,6),@LtsBufala int,@PrecBufala dec(8,6), @LtsFrios int
	
			set @PrecioMin = (SELECT MIN(Precio) AS Precio FROM Distancias_Acarreo WHERE (Precio > 0))
			set @PrecioMax = (SELECT max(Precio) AS Precio FROM Distancias_Acarreo)
			set @PrecioMed = (SELECT MAX(Precio) AS Precio FROM Distancias_Acarreo WHERE (Precio <
			                 (SELECT MAX(Precio) AS Precio FROM Distancias_Acarreo AS Distancias_Acarreo_1)))
			set @PrecioFrio = (SELECT MIN(PrecioLecheFria) AS PrecFrio FROM Precio_Queso)
			
						 
	 if @Empresa = 0
	 begin
	 	
	--Insertar Leche de vaca
	DECLARE cursorPrecio cursor for	
	SELECT        SUM(Litros) AS Litros, SUM(Importe) / SUM(Litros) AS Precio
	FROM            (SELECT        SUM([Vale de Compra].Litros) AS Litros, SUM([Vale de Compra].Litros * [Vale de Compra].Precio) AS Importe
	                          FROM            [Registro Diario] INNER JOIN
	                                                    [Vale de Compra] ON [Registro Diario].Id_Diario = [Vale de Compra].Id_Diario INNER JOIN
	                                                    Pto_Recogida ON [Vale de Compra].Codigo = Pto_Recogida.Codigo INNER JOIN
	                                                    Entidad ON Pto_Recogida.Id_Entidad = Entidad.Id_Entidad
	                          WHERE        ([Registro Diario].Mes_Anho = @mesAnho) AND (Entidad.Id_Entidad = @idEntidad) AND ([Vale de Compra].TipoLeche = 1)
	                          UNION
	                          SELECT        SUM(LecheDejadaAcopiar.Litros) AS Litros, SUM(LecheDejadaAcopiar.Litros * LecheDejadaAcopiar.Precio) AS Importe
	                          FROM            LecheDejadaAcopiar INNER JOIN
	                                                   Pto_Recogida AS Pto_Recogida_1 ON LecheDejadaAcopiar.Codigo = Pto_Recogida_1.Codigo INNER JOIN
	                                                   Entidad AS Entidad_1 ON Pto_Recogida_1.Id_Entidad = Entidad_1.Id_Entidad
	                          WHERE        (LecheDejadaAcopiar.MesAnho = @mesAnho) AND (LecheDejadaAcopiar.TipoLeche = 1) AND (Entidad_1.Id_Entidad = @identidad)) AS derivedtbl_1    
        
     open cursorPrecio
	FETCH NEXT FROM cursorPrecio
	INTO @LtsVaca,@PrecVaca
	CLOSE cursorPrecio
	DEALLOCATE cursorPrecio
		
			
	--Insertar Leche de cabra
	DECLARE cursorPrecio1 cursor for
	SELECT  SUM(Litros) AS Litros, SUM(Importe) / SUM(Litros) AS Precio
	FROM            (SELECT        SUM([Vale de Compra].Litros) AS Litros, SUM([Vale de Compra].Litros * [Vale de Compra].Precio) AS Importe
	                          FROM            [Registro Diario] INNER JOIN
	                                                    [Vale de Compra] ON [Registro Diario].Id_Diario = [Vale de Compra].Id_Diario INNER JOIN
	                                                    Pto_Recogida ON [Vale de Compra].Codigo = Pto_Recogida.Codigo INNER JOIN
	                                                    Entidad ON Pto_Recogida.Id_Entidad = Entidad.Id_Entidad
	                          WHERE        ([Registro Diario].Mes_Anho = @mesAnho) AND (Entidad.Id_Entidad = @idEntidad) AND ([Vale de Compra].TipoLeche = 3)
	                          UNION
	                          SELECT        SUM(LecheDejadaAcopiar.Litros) AS Litros, SUM(LecheDejadaAcopiar.Litros * LecheDejadaAcopiar.Precio) AS Importe
	                          FROM            LecheDejadaAcopiar INNER JOIN
	                                                   Pto_Recogida AS Pto_Recogida_1 ON LecheDejadaAcopiar.Codigo = Pto_Recogida_1.Codigo INNER JOIN
	                                                   Entidad AS Entidad_1 ON Pto_Recogida_1.Id_Entidad = Entidad_1.Id_Entidad
	                          WHERE        (LecheDejadaAcopiar.MesAnho = @mesAnho) AND (LecheDejadaAcopiar.TipoLeche = 3) AND (Entidad_1.Id_Entidad = @identidad)) AS derivedtbl_1    
          
	open cursorPrecio1
	FETCH NEXT FROM cursorPrecio1
	INTO @LtsCabra,@PrecCabra
	CLOSE cursorPrecio1
	DEALLOCATE cursorPrecio1
	
		--Insertar Leche de bufala
	DECLARE cursorPrecio2 cursor for
	SELECT        SUM(Litros) AS Litros, SUM(Importe) / SUM(Litros) AS Precio
	FROM            (SELECT        SUM([Vale de Compra].Litros) AS Litros, SUM([Vale de Compra].Litros * [Vale de Compra].Precio) AS Importe
	                          FROM            [Registro Diario] INNER JOIN
	                                                    [Vale de Compra] ON [Registro Diario].Id_Diario = [Vale de Compra].Id_Diario INNER JOIN
	                                                    Pto_Recogida ON [Vale de Compra].Codigo = Pto_Recogida.Codigo INNER JOIN
	                                                    Entidad ON Pto_Recogida.Id_Entidad = Entidad.Id_Entidad
	                          WHERE        ([Registro Diario].Mes_Anho = @mesAnho) AND (Entidad.Id_Entidad = @idEntidad) AND ([Vale de Compra].TipoLeche = 2)
	                          UNION
	                          SELECT        SUM(LecheDejadaAcopiar.Litros) AS Litros, SUM(LecheDejadaAcopiar.Litros * LecheDejadaAcopiar.Precio) AS Importe
	                          FROM            LecheDejadaAcopiar INNER JOIN
	                                                   Pto_Recogida AS Pto_Recogida_1 ON LecheDejadaAcopiar.Codigo = Pto_Recogida_1.Codigo INNER JOIN
	                                                   Entidad AS Entidad_1 ON Pto_Recogida_1.Id_Entidad = Entidad_1.Id_Entidad
	                          WHERE        (LecheDejadaAcopiar.MesAnho = @mesAnho) AND (LecheDejadaAcopiar.TipoLeche = 2) AND (Entidad_1.Id_Entidad = @identidad)) AS derivedtbl_1    
          
	open cursorPrecio2
	FETCH NEXT FROM cursorPrecio2
	INTO @LtsBufala,@PrecBufala
	CLOSE cursorPrecio2
	DEALLOCATE cursorPrecio2
	
	--Nuevo insertar Leche Fría
	DECLARE cursorPrecio3 cursor for
	SELECT        SUM(LitrosFrios) AS LitrosFrios
	FROM            (SELECT        SUM([Vale de Compra].Litros) AS LitrosFrios
	                 FROM            [Registro Diario] INNER JOIN
	                                          [Vale de Compra] ON [Registro Diario].Id_Diario = [Vale de Compra].Id_Diario INNER JOIN
	                                          Pto_Recogida ON [Vale de Compra].Codigo = Pto_Recogida.Codigo INNER JOIN
	                                          Entidad ON Pto_Recogida.Id_Entidad = Entidad.Id_Entidad
	                 WHERE        ([Registro Diario].Mes_Anho = @mesAnho) AND (Entidad.Id_Entidad = @idEntidad) AND ([Vale de Compra].LecheFria = 1)
	                          UNION
	                          SELECT        SUM(LecheDejadaAcopiar.Litros) AS LitrosFrios
	                          FROM            LecheDejadaAcopiar INNER JOIN
	                                                   Pto_Recogida AS Pto_Recogida_1 ON LecheDejadaAcopiar.Codigo = Pto_Recogida_1.Codigo INNER JOIN
	                                                   Entidad AS Entidad_1 ON Pto_Recogida_1.Id_Entidad = Entidad_1.Id_Entidad
	                          WHERE        (LecheDejadaAcopiar.MesAnho = @mesAnho) AND (Entidad_1.Id_Entidad = @identidad)) AS derivedtbl_1    
          
	open cursorPrecio3
	FETCH NEXT FROM cursorPrecio3
	INTO @LtsFrios
	CLOSE cursorPrecio3
	DEALLOCATE cursorPrecio3

		if(@PrecCabra is null) set @PrecCabra =0
		if(@PrecBufala is null) set @PrecBufala =0
		if(@PrecVaca is null) set @PrecVaca =0
		if(@LtsCabra is null) set @LtsCabra =0
		if(@LtsBufala is null) set @LtsBufala =0
		if(@LtsVaca is null) set @LtsVaca =0
		if(@LtsFrios is null) set @LtsFrios =0
		
	INSERT INTO ActaConciliacion
	                         (IdEntidad, mesAnho, Entidad, Municipio, LtsVaca, LtsBufala, LtsCabra, PrecVaca, PrecBufala, PrecCabra, 
	                         Prec3km, Prec5km, PrecMy5km, PrecFrio, Fecha, LtsFrios)
           SELECT        Entidad.Id_Entidad,@mesAnho, Entidad.Nombre AS Entidad, Municipio.Nombre AS Municipio,@LtsVaca,@LtsBufala,
           @LtsCabra,@PrecVaca,@PrecBufala,@PrecCabra,@PrecioMin,@PrecioMed,@PrecioMax,@PrecioFrio,GetDate(),@LtsFrios
           FROM            Entidad INNER JOIN
                                    Municipio ON Entidad.Id_Municipio = Municipio.Id_Municipio
           WHERE        (Entidad.Id_Entidad = @idEntidad)     
                
                 /*  SELECT        IdEntidad, @mesAnho AS Mes, Entidad, Municipio, LtsVaca, LtsBufala, LtsCabra, PrecioVaca, PrecioBufala, PrecioCabra, Prec3km, Prec5km, PrecMy5km, 
                                            PrecFria, GETDATE() AS Fecha
                   FROM            dbo.FunctionFacturacion(@mesAnho) AS FunctionFacturacion_1
                   WHERE        (IdEntidad = @IdEntidad)  */
                   
   --Insertar Plan de las CCS
    UPDATE       ActaConciliacion
   SET                Planificado = plani.Litros
   FROM            ActaConciliacion INNER JOIN
                                (SELECT        SUM(Litros) AS Litros, Id_Entidad
                                 FROM            (SELECT        SUM(PlanProdAcomodado.Litros) AS Litros, Entidad.Id_Entidad
                                                           FROM            Entidad INNER JOIN
                                                                                     Pto_Recogida ON Entidad.Id_Entidad = Pto_Recogida.Id_Entidad INNER JOIN
                                                                                     PlanProdAcomodado ON Pto_Recogida.Codigo = PlanProdAcomodado.Id_Productor
                                                           WHERE        (PlanProdAcomodado.Fecha BETWEEN CAST('1/1/' + DATENAME(year, @mesAnho) AS Datetime) AND @mesAnho) AND
                                                                                      (PlanProdAcomodado.Id_Tipo_Leche = 1)
                                                           GROUP BY Entidad.Id_Entidad
                                                           HAVING         (Entidad.Id_Entidad = @IdEntidad)
                                                           /*UNION
                                                           SELECT        SUM(PlanAcomodado.Litros) AS Litros, PlanAcomodado.Id_Entidad
                                                           FROM            PlanAcomodado INNER JOIN
                                                                                    Entidad ON PlanAcomodado.Id_Entidad = Entidad.Id_Entidad
                                                           WHERE        (PlanAcomodado.Fecha BETWEEN CAST('1/1/' + DATENAME(year, @mesAnho) AS Datetime) AND @mesAnho)  AND 
                                                                                    (PlanAcomodado.Id_Tipo_Leche <> 1)
                                                           GROUP BY PlanAcomodado.Id_Entidad
                                                           HAVING        (PlanAcomodado.Id_Entidad = @IdEntidad)*/) AS Planes
                                 GROUP BY Id_Entidad) AS plani ON ActaConciliacion.IdEntidad = plani.Id_Entidad
   WHERE        (ActaConciliacion.mesAnho = @mesAnho) 
   
   --Insertar plan de los que no son CCS                
   UPDATE       ActaConciliacion
   SET                Planificado = plani.Litros + ActaConciliacion.Planificado
   FROM            ActaConciliacion INNER JOIN
                                (SELECT        SUM(PlanAcomodado.Litros) AS Litros, PlanAcomodado.Id_Entidad
                                 FROM            PlanAcomodado INNER JOIN
                                                          Entidad ON PlanAcomodado.Id_Entidad = Entidad.Id_Entidad
                                 WHERE        (PlanAcomodado.Fecha BETWEEN CAST('1/1/' + DATENAME(year, @mesAnho) AS Datetime) AND @mesAnho)
                                 GROUP BY PlanAcomodado.Id_Entidad
                                 HAVING        (PlanAcomodado.Id_Entidad = @IdEntidad)) AS plani ON ActaConciliacion.IdEntidad = plani.Id_Entidad
   WHERE        (ActaConciliacion.mesAnho = @mesAnho)
                   
    UPDATE       ActaConciliacion
    SET                Realizado = calculo.Realizado
    FROM            ActaConciliacion INNER JOIN
                                 (SELECT        SUM(LitrosTotal) AS Realizado, IdEntidad
                                   FROM            ActaConciliacion AS ActaConciliacion_1
                                   WHERE        (mesAnho BETWEEN CAST('1/1/' + DATENAME(year, @mesAnho) AS Datetime) AND @mesAnho)
                                   GROUP BY IdEntidad
                                   HAVING         (IdEntidad = @IdEntidad)) AS calculo ON ActaConciliacion.IdEntidad = calculo.IdEntidad
    WHERE        (ActaConciliacion.mesAnho = @mesAnho)    
                   end
     else
     begin
     
     DECLARE cursorPrecio cursor for	
	SELECT        SUM(Litros) AS Litros, SUM(Importe) / SUM(Litros) AS Precio
	FROM            (SELECT        SUM([Vale de Compra].Litros) AS Litros, SUM([Vale de Compra].Litros * [Vale de Compra].Precio) AS Importe
	                 FROM            [Registro Diario] INNER JOIN
	                                          [Vale de Compra] ON [Registro Diario].Id_Diario = [Vale de Compra].Id_Diario INNER JOIN
	                                          Pto_Recogida ON [Vale de Compra].Codigo = Pto_Recogida.Codigo INNER JOIN
	                                          Entidad ON Pto_Recogida.Id_Entidad = Entidad.Id_Entidad INNER JOIN
	                                          Empresa ON Entidad.IdEmpresa = Empresa.Id_Empresa
	                 WHERE        ([Registro Diario].Mes_Anho = @mesAnho) AND ([Vale de Compra].TipoLeche = 1) AND (Empresa.Id_Empresa = @idEntidad)   
	                       UNION
	                          SELECT        SUM(LecheDejadaAcopiar.Litros) AS Litros, SUM(LecheDejadaAcopiar.Litros * LecheDejadaAcopiar.Precio) AS Importe
	                          FROM            LecheDejadaAcopiar INNER JOIN
	                                                   Pto_Recogida AS Pto_Recogida_1 ON LecheDejadaAcopiar.Codigo = Pto_Recogida_1.Codigo INNER JOIN
	                                                   Entidad AS Entidad_1 ON Pto_Recogida_1.Id_Entidad = Entidad_1.Id_Entidad INNER JOIN
	                                                   Empresa ON Entidad_1.IdEmpresa = Empresa.Id_Empresa
	                          WHERE        (LecheDejadaAcopiar.MesAnho = @mesAnho) AND (LecheDejadaAcopiar.TipoLeche = 1) AND (Empresa.Id_Empresa = @identidad)) AS derivedtbl_1    
        
     open cursorPrecio
	FETCH NEXT FROM cursorPrecio
	INTO @LtsVaca,@PrecVaca
	CLOSE cursorPrecio
	DEALLOCATE cursorPrecio
	
	--insertar leche cabra
	
     DECLARE cursorPrecio1 cursor for	
	SELECT        SUM(Litros) AS Litros, SUM(Importe) / SUM(Litros) AS Precio
	FROM            (SELECT        SUM([Vale de Compra].Litros) AS Litros, SUM([Vale de Compra].Litros * [Vale de Compra].Precio) AS Importe
	                 FROM            [Registro Diario] INNER JOIN
	                                          [Vale de Compra] ON [Registro Diario].Id_Diario = [Vale de Compra].Id_Diario INNER JOIN
	                                          Pto_Recogida ON [Vale de Compra].Codigo = Pto_Recogida.Codigo INNER JOIN
	                                          Entidad ON Pto_Recogida.Id_Entidad = Entidad.Id_Entidad INNER JOIN
	                                          Empresa ON Entidad.IdEmpresa = Empresa.Id_Empresa
	                 WHERE        ([Registro Diario].Mes_Anho = @mesAnho) AND ([Vale de Compra].TipoLeche = 3) AND (Empresa.Id_Empresa = @idEntidad)   
	                       UNION
	                          SELECT        SUM(LecheDejadaAcopiar.Litros) AS Litros, SUM(LecheDejadaAcopiar.Litros * LecheDejadaAcopiar.Precio) AS Importe
	                          FROM            LecheDejadaAcopiar INNER JOIN
	                                                   Pto_Recogida AS Pto_Recogida_1 ON LecheDejadaAcopiar.Codigo = Pto_Recogida_1.Codigo INNER JOIN
	                                                   Entidad AS Entidad_1 ON Pto_Recogida_1.Id_Entidad = Entidad_1.Id_Entidad INNER JOIN
	                                                   Empresa ON Entidad_1.IdEmpresa = Empresa.Id_Empresa
	                          WHERE        (LecheDejadaAcopiar.MesAnho = @mesAnho) AND (LecheDejadaAcopiar.TipoLeche = 3) AND (Empresa.Id_Empresa = @identidad)) AS derivedtbl_1    
        
     open cursorPrecio1
	FETCH NEXT FROM cursorPrecio1
	INTO @LtsCabra,@PrecCabra
	CLOSE cursorPrecio1
	DEALLOCATE cursorPrecio1
	
	--insertar leche de bufala
	
     DECLARE cursorPrecio2 cursor for	
	SELECT        SUM(Litros) AS Litros, SUM(Importe) / SUM(Litros) AS Precio
	FROM            (SELECT        SUM([Vale de Compra].Litros) AS Litros, SUM([Vale de Compra].Litros * [Vale de Compra].Precio) AS Importe
	                 FROM            [Registro Diario] INNER JOIN
	                                          [Vale de Compra] ON [Registro Diario].Id_Diario = [Vale de Compra].Id_Diario INNER JOIN
	                                          Pto_Recogida ON [Vale de Compra].Codigo = Pto_Recogida.Codigo INNER JOIN
	                                          Entidad ON Pto_Recogida.Id_Entidad = Entidad.Id_Entidad INNER JOIN
	                                          Empresa ON Entidad.IdEmpresa = Empresa.Id_Empresa
	                 WHERE        ([Registro Diario].Mes_Anho = @mesAnho) AND ([Vale de Compra].TipoLeche = 2) AND (Empresa.Id_Empresa = @idEntidad)   
	                       UNION
	                          SELECT        SUM(LecheDejadaAcopiar.Litros) AS Litros, SUM(LecheDejadaAcopiar.Litros * LecheDejadaAcopiar.Precio) AS Importe
	                          FROM            LecheDejadaAcopiar INNER JOIN
	                                                   Pto_Recogida AS Pto_Recogida_1 ON LecheDejadaAcopiar.Codigo = Pto_Recogida_1.Codigo INNER JOIN
	                                                   Entidad AS Entidad_1 ON Pto_Recogida_1.Id_Entidad = Entidad_1.Id_Entidad INNER JOIN
	                                                   Empresa ON Entidad_1.IdEmpresa = Empresa.Id_Empresa
	                          WHERE        (LecheDejadaAcopiar.MesAnho = @mesAnho) AND (LecheDejadaAcopiar.TipoLeche = 2) AND (Empresa.Id_Empresa = @identidad)) AS derivedtbl_1    
        
     open cursorPrecio2
	FETCH NEXT FROM cursorPrecio2
	INTO @LtsBufala,@PrecBufala
	CLOSE cursorPrecio2
	DEALLOCATE cursorPrecio2
	
	--Nuevo insertar Leche Fría
	DECLARE cursorPrecio3 cursor for	
	SELECT        SUM(LitrosFrios) AS LitrosFrios
	FROM            (SELECT        SUM([Vale de Compra].Litros) AS LitrosFrios
	                 FROM            [Registro Diario] INNER JOIN
	                                          [Vale de Compra] ON [Registro Diario].Id_Diario = [Vale de Compra].Id_Diario INNER JOIN
	                                          Pto_Recogida ON [Vale de Compra].Codigo = Pto_Recogida.Codigo INNER JOIN
	                                          Entidad ON Pto_Recogida.Id_Entidad = Entidad.Id_Entidad INNER JOIN
	                                          Empresa ON Entidad.IdEmpresa = Empresa.Id_Empresa
	                 WHERE        ([Registro Diario].Mes_Anho = @mesAnho) AND (Empresa.Id_Empresa = @idEntidad) AND ([Vale de Compra].LecheFria = 1)
	                       UNION
	                          SELECT        SUM(LecheDejadaAcopiar.Litros) AS LitrosFrios
	                          FROM            LecheDejadaAcopiar INNER JOIN
	                                                   Pto_Recogida AS Pto_Recogida_1 ON LecheDejadaAcopiar.Codigo = Pto_Recogida_1.Codigo INNER JOIN
	                                                   Entidad AS Entidad_1 ON Pto_Recogida_1.Id_Entidad = Entidad_1.Id_Entidad INNER JOIN
	                                                   Empresa ON Entidad_1.IdEmpresa = Empresa.Id_Empresa
	                          WHERE        (LecheDejadaAcopiar.MesAnho = @mesAnho) AND (Empresa.Id_Empresa = @identidad)) AS derivedtbl_1      
          
	open cursorPrecio3
	FETCH NEXT FROM cursorPrecio3
	INTO @LtsFrios
	CLOSE cursorPrecio3
	DEALLOCATE cursorPrecio3
	
     if(@PrecCabra is null) set @PrecCabra =0
		if(@PrecBufala is null) set @PrecBufala =0
		if(@PrecVaca is null) set @PrecVaca =0
		if(@LtsCabra is null) set @LtsCabra =0
		if(@LtsBufala is null) set @LtsBufala =0
		if(@LtsVaca is null) set @LtsVaca =0
		if(@LtsFrios is null) set @LtsFrios =0
     
     
     INSERT INTO ActaConciliacion
                      (IdEntidad, mesAnho, Entidad, Municipio, LtsVaca, LtsBufala, LtsCabra, PrecVaca, PrecBufala, PrecCabra, Prec3km, Prec5km, PrecMy5km, PrecFrio, Fecha, LtsFrios)
                 SELECT        Entidad.Id_Entidad, @mesAnho AS Expr1, Entidad.Nombre AS Entidad, Municipio.Nombre AS Municipio, @LtsVaca AS Expr2, @LtsBufala AS Expr3, 
                                          @LtsCabra AS Expr4, @PrecVaca AS Expr5, @PrecBufala AS Expr6, @PrecCabra AS Expr7, @PrecioMin AS Expr8, @PrecioMed AS Expr9, @PrecioMax AS Expr10, 
                                          @PrecioFrio AS Expr11, GETDATE() AS Expr12, @LtsFrios
                 FROM            Entidad INNER JOIN
                                          Municipio ON Entidad.Id_Municipio = Municipio.Id_Municipio INNER JOIN
                                          Empresa ON Entidad.IdEmpresa = Empresa.Id_Empresa AND Entidad.Nombre = Empresa.Nombre
                 WHERE        (Empresa.Id_Empresa = @idEntidad)     
          
                
                  /* SELECT     IdEntidad, @mesAnho AS Mes, Empresa, Municipio, LtsVaca, LtsBufala, LtsCabra, PrecioVaca, PrecioBufala, PrecioCabra, Prec3km, Prec5km, 
                                         PrecMy5km, PrecFria, GETDATE() AS Fecha
                   FROM         dbo.FunctionFacturacionEmpresa(@mesAnho) AS FunctionFacturacion_1
                   WHERE     (IdEntidad = @IdEntidad)  */
                   
                    UPDATE       ActaConciliacion
                    SET                Planificado = plani.Litros
                    FROM            ActaConciliacion INNER JOIN
                                                 (SELECT        SUM(PlanAcomodado.Litros) AS Litros, PlanAcomodado.Id_Entidad
                                                   FROM            PlanAcomodado INNER JOIN
                                                                             Entidad ON PlanAcomodado.Id_Entidad = Entidad.Id_Entidad INNER JOIN
                                                                             Empresa ON Entidad.IdEmpresa = Empresa.Id_Empresa AND Entidad.Nombre = Empresa.Nombre
                                                   WHERE        (PlanAcomodado.Fecha BETWEEN CAST('1/1/' + DATENAME(year, @mesAnho) AS Datetime) AND @mesAnho) AND 
                                                                             (Empresa.Id_Empresa = @IdEntidad)
                                                   GROUP BY PlanAcomodado.Id_Entidad) AS plani ON ActaConciliacion.IdEntidad = plani.Id_Entidad
                    WHERE        (ActaConciliacion.mesAnho = @mesAnho)   
   
                   
    UPDATE       ActaConciliacion
    SET                Realizado = calculo.Realizado
    FROM            ActaConciliacion INNER JOIN
                                 (SELECT        SUM(ActaConciliacion_1.LitrosTotal) AS Realizado, ActaConciliacion_1.IdEntidad
                                   FROM            Empresa INNER JOIN
                                                             Entidad ON Empresa.Id_Empresa = Entidad.IdEmpresa AND Empresa.Nombre = Entidad.Nombre INNER JOIN
                                                             ActaConciliacion AS ActaConciliacion_1 ON Entidad.Id_Entidad = ActaConciliacion_1.IdEntidad
                                   WHERE        (ActaConciliacion_1.mesAnho BETWEEN CAST('1/1/' + DATENAME(year, @mesAnho) AS Datetime) AND @mesAnho) AND 
                                                             (Empresa.Id_Empresa = @IdEntidad)
                                   GROUP BY ActaConciliacion_1.IdEntidad) AS calculo ON ActaConciliacion.IdEntidad = calculo.IdEntidad
    WHERE        (ActaConciliacion.mesAnho = @mesAnho)    
                   end
	RETURN




GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

ALTER  VIEW dbo.Planificado
AS
SELECT        dbo.Clasificacion.Clasificacion, dbo.Clasificacion.Sector, dbo.Municipio.Nombre AS Municipio, dbo.Empresa.Pertenece, dbo.PlanAcomodado.Fecha, 
                         SUM(dbo.PlanAcomodado.Litros) AS Planificado, dbo.[Tipo de Animal].Nombre AS TipoLeche, dbo.Empresa.Nombre AS Empresa
FROM            dbo.Municipio INNER JOIN
                         dbo.Entidad ON dbo.Municipio.Id_Municipio = dbo.Entidad.Id_Municipio INNER JOIN
                         dbo.Clasificacion ON dbo.Entidad.Id_Clasificacion = dbo.Clasificacion.Id_Clasificacion INNER JOIN
                         dbo.PlanAcomodado ON dbo.Entidad.Id_Entidad = dbo.PlanAcomodado.Id_Entidad INNER JOIN
                         dbo.Empresa ON dbo.Entidad.IdEmpresa = dbo.Empresa.Id_Empresa INNER JOIN
                         dbo.[Tipo de Animal] ON dbo.PlanAcomodado.Id_Tipo_Leche = dbo.[Tipo de Animal].Id_Animal
GROUP BY dbo.Clasificacion.Clasificacion, dbo.Clasificacion.Sector, dbo.Municipio.Nombre, dbo.Empresa.Pertenece, dbo.PlanAcomodado.Fecha, dbo.[Tipo de Animal].Nombre, 
                         dbo.Empresa.Nombre
UNION
SELECT        Clasificacion_1.Clasificacion, Clasificacion_1.Sector, Municipio_1.Nombre AS Municipio, Empresa_1.Pertenece, dbo.PlanProdAcomodado.Fecha, 
                         SUM(dbo.PlanProdAcomodado.Litros) AS Planificado, [Tipo de Animal_1].Nombre AS TipoLeche, Empresa_1.Nombre AS Empresa
FROM            dbo.Municipio AS Municipio_1 INNER JOIN
                         dbo.Entidad AS Entidad_1 ON Municipio_1.Id_Municipio = Entidad_1.Id_Municipio INNER JOIN
                         dbo.Clasificacion AS Clasificacion_1 ON Entidad_1.Id_Clasificacion = Clasificacion_1.Id_Clasificacion INNER JOIN
                         dbo.Empresa AS Empresa_1 ON Entidad_1.IdEmpresa = Empresa_1.Id_Empresa INNER JOIN
                         dbo.Pto_Recogida ON Entidad_1.Id_Entidad = dbo.Pto_Recogida.Id_Entidad INNER JOIN
                         dbo.PlanProdAcomodado ON dbo.Pto_Recogida.Codigo = dbo.PlanProdAcomodado.Id_Productor INNER JOIN
                         dbo.[Tipo de Animal] AS [Tipo de Animal_1] ON dbo.PlanProdAcomodado.Id_Tipo_Leche = [Tipo de Animal_1].Id_Animal
GROUP BY Clasificacion_1.Clasificacion, Clasificacion_1.Sector, Municipio_1.Nombre, Empresa_1.Pertenece, dbo.PlanProdAcomodado.Fecha, [Tipo de Animal_1].Nombre, 
                         Empresa_1.Nombre

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO