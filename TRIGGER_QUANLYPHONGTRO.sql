CREATE TRIGGER [dbo].[CHECK_HOADON]
ON [dbo].[CT_HOADON]
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @MAHOADON NCHAR(11), @MAPHONG VARCHAR(4)
	SELECT @MAHOADON = MAHOADON,
		   @MAPHONG = MAPHONG
	FROM inserted

	IF (NOT EXISTS(SELECT 1 FROM HOADON WHERE MAHOADON = @MAHOADON AND MAPHONG = @MAPHONG))
	BEGIN
		RAISERROR('MÃ HÓA ĐƠN HOẶC MÃ PHÒNG KHÔNG ĐÚNG.', 16, 1)
		ROLLBACK TRANSACTION
	END
END

GO
/****** Object:  Trigger [dbo].[CHECK_NGAYDONG]    Script Date: 06/22/2024 3:19:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[CHECK_NGAYDONG]
ON [dbo].[CT_HOADON]
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @MAHOADON NCHAR(11), @NGAYDONG DATETIME, @NGAYLAP DATE
	SELECT @MAHOADON = MAHOADON,
		   @NGAYDONG = NGAYDONG
	FROM inserted
	SET @NGAYLAP = (SELECT NGAYLAP FROM HOADON WHERE MAHOADON = @MAHOADON)
	IF (CAST(@NGAYDONG AS DATE) < @NGAYLAP)
	BEGIN
		RAISERROR('NGÀY ĐÓNG TRƯỚC NGÀY LẬP!', 16, 1)
		ROLLBACK TRANSACTION
	END

	IF (DATEDIFF(DAY, CAST(@NGAYDONG AS DATE), @NGAYDONG) > 14)
	BEGIN
		RAISERROR('HẾT HẠN ĐÓNG TIỀN', 16, 1)
		ROLLBACK TRANSACTION
	END
END

GO
/****** Object:  Trigger [dbo].[UPDATE_NOPTIEN_HOADON]    Script Date: 06/22/2024 3:19:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[UPDATE_NOPTIEN_HOADON]
ON [dbo].[CT_HOADON]
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @MAHOADON NCHAR(11), @MAPHONG VARCHAR(4), @NGAYDONG DATETIME, @SOTIEN MONEY
	SELECT @MAHOADON = MAHOADON,
		   @MAPHONG = MAPHONG,
		   @NGAYDONG = NGAYDONG,
		   @SOTIEN = SOTIENDONG
	FROM inserted

	UPDATE HOADON
	SET TONGTIENDADONG = TONGTIENDADONG + @SOTIEN
	WHERE MAHOADON = @MAHOADON
END

GO
/****** Object:  Trigger [dbo].[CHECK_NGAYTHUE]    Script Date: 06/22/2024 3:19:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[CHECK_NGAYTHUE]
ON [dbo].[CT_THUE]
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @MAPHONG VARCHAR(4), @NGAYTHUE DATE, @NGAYBDTHUE DATE
	IF (UPDATE(NGAYTHUE))
	BEGIN
		SELECT @MAPHONG = MAPHONG,
			   @NGAYTHUE = NGAYTHUE
		FROM inserted
		
		SET @NGAYBDTHUE = (SELECT TOP 1 NGAYBDTHUE FROM HOPDONG WITH(INDEX=IX_NGAYLAP) WHERE MAPHONG = @MAPHONG)

		IF (@NGAYTHUE < @NGAYBDTHUE)
		BEGIN
			RAISERROR('KHÔNG ĐƯỢC THUÊ TRƯỚC NGÀY BẮT ĐẦU THUÊ.', 16, 1)
			ROLLBACK TRANSACTION
		END	 
	END
END


GO
/****** Object:  Trigger [dbo].[TRG_CHECK_KHACHTHUE_PHONG]    Script Date: 06/22/2024 3:19:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TRG_CHECK_KHACHTHUE_PHONG]
ON [dbo].[CT_THUE]
AFTER INSERT
AS
BEGIN
	DECLARE @MAPHONG VARCHAR(4), @MAKHACHTHUE INT

	SELECT @MAPHONG = MAPHONG,
		@MAKHACHTHUE = MAKHACHTHUE
	FROM inserted

	IF (EXISTS(SELECT 1 FROM CT_THUE WHERE MAKHACHTHUE = @MAKHACHTHUE AND NGAYTRA IS NULL))
	BEGIN
		RAISERROR('KHÁCH THUÊ CHƯA TRẢ PHÒNG, KHÔNG THỂ THUÊ PHÒNG KHÁC', 16, 1)
		ROLLBACK TRANSACTION
	END
	

END
GO
/****** Object:  Trigger [dbo].[TRG_CHECK_PHONG_TRONG]    Script Date: 06/22/2024 3:19:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TRG_CHECK_PHONG_TRONG]
ON [dbo].[CT_THUE]
AFTER INSERT
AS
BEGIN
	DECLARE @MAPHONG VARCHAR(4), @MAKHACHTHUE INT, @TRANGTHAIPHONG NVARCHAR(30)

	SELECT @MAPHONG = MAPHONG,
		@MAKHACHTHUE = MAKHACHTHUE
	FROM inserted

	SELECT @TRANGTHAIPHONG = TRANGTHAI FROM PHONG WHERE MAPHONG = @MAPHONG

	IF (@TRANGTHAIPHONG = N'Trống')
	BEGIN
		RAISERROR('PHÒNG NÀY CHƯA ĐƯỢC LẬP HỢP ĐỒNG, PHẢI LẬP HỢP ĐỒNG MỚI ĐƯỢC THÊM KHÁCH THUÊ VÀO!', 16, 1)
		ROLLBACK TRANSACTION
	END
END
GO
/****** Object:  Trigger [dbo].[TRG_CHECK_SL_KHACHTHUE]    Script Date: 06/22/2024 3:19:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TRG_CHECK_SL_KHACHTHUE]
ON [dbo].[CT_THUE]
AFTER INSERT
AS
BEGIN
	DECLARE @MAPHONG VARCHAR(4), @SLKHACHTHUE INT, @SLKHACHTHUETT INT, @SLKHACHTHUETD INT

	SELECT @MAPHONG = MAPHONG
	FROM inserted

	SELECT @SLKHACHTHUE = SLKHACHTHUE FROM HOPDONG WHERE MAPHONG = @MAPHONG AND TRANGTHAIHD = N'Đang hiệu lực'
	SELECT @SLKHACHTHUETD = SLKHACHTHUETOIDA FROM PHONG WHERE MAPHONG = @MAPHONG AND TRANGTHAI = N'Đã thuê'

	SELECT @SLKHACHTHUETT = COUNT(*)
	FROM CT_THUE
	WHERE MAPHONG = @MAPHONG AND NGAYTRA IS NULL

	IF (@SLKHACHTHUE < @SLKHACHTHUETT)
	BEGIN
		RAISERROR('Số lượng khách thuê trong phòng đã đủ không thể thêm!', 16, 1)
		ROLLBACK TRANSACTION
	END

	IF (@SLKHACHTHUETD < @SLKHACHTHUETT)
	BEGIN
		RAISERROR('Số lượng khách thuê trong phòng đã vượt quá giới hạn cho phép!', 16, 1)
		ROLLBACK TRANSACTION
	END

END

GO
/****** Object:  Trigger [dbo].[TRG_UPDATE_TRANGTHAIHD_PHONG]    Script Date: 06/22/2024 3:19:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TRG_UPDATE_TRANGTHAIHD_PHONG]
ON [dbo].[CT_THUE]
AFTER UPDATE
AS
BEGIN
	IF (UPDATE(NGAYTRA))
    BEGIN
        DECLARE @MAPHONG VARCHAR(4), @NGAYTRA DATE, @CNT INT, @NGAYHETHAN DATE, @MAHOPDONG VARCHAR(8)

		SELECT @MAPHONG = MAPHONG, @NGAYTRA = NGAYTRA FROM inserted
        SELECT @CNT = COUNT(*) FROM CT_THUE WHERE NGAYTRA IS NULL AND MAPHONG = @MAPHONG
		SELECT @MAHOPDONG = MAHOPDONG, @NGAYHETHAN = HD.NGAYHETHAN 
		FROM (SELECT TOP 1 * FROM HOPDONG WITH(INDEX(IX_NGAYLAP)) WHERE MAPHONG = @MAPHONG) HD

		BEGIN TRANSACTION
		BEGIN TRY
        IF @CNT = 0
        BEGIN
			IF (@NGAYTRA < @NGAYHETHAN)
			BEGIN
				UPDATE HOPDONG
				SET TRANGTHAIHD = N'Đã hủy'
				WHERE MAHOPDONG = @MAHOPDONG AND MAPHONG = @MAPHONG
			END
			ELSE
			BEGIN
				UPDATE HOPDONG
				SET TRANGTHAIHD = N'Đã hết hạn'
				WHERE MAHOPDONG = @MAHOPDONG AND MAPHONG = @MAPHONG
			END

			UPDATE PHONG
            SET TRANGTHAI = N'Trống'
            WHERE MAPHONG = @MAPHONG AND TRANGTHAI = N'Đã thuê'
        END
		COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION
		END CATCH
    END
END
GO
/****** Object:  Trigger [dbo].[TRG_UPDATE_TRANGTHAIPHONG]    Script Date: 06/22/2024 3:19:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TRG_UPDATE_TRANGTHAIPHONG]
ON [dbo].[CT_THUE]
AFTER INSERT, UPDATE

AS
BEGIN
	DECLARE @MAPHONG VARCHAR(4)
	IF (UPDATE(NGAYTHUE))
	BEGIN
		SELECT @MAPHONG = MAPHONG FROM INSERTED;

		UPDATE PHONG
		SET TRANGTHAI = N'Đã thuê'
		WHERE PHONG.MAPHONG = @MAPHONG
	END
END
GO
/****** Object:  Trigger [dbo].[CAPNHATTRANGTHAIPHONG]    Script Date: 06/22/2024 3:19:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[CAPNHATTRANGTHAIPHONG]
ON [dbo].[HOPDONG]
AFTER INSERT, UPDATE
AS
BEGIN
	IF (EXISTS(SELECT 1 FROM inserted))
	BEGIN
		UPDATE PHONG
		SET TRANGTHAI = N'Đã đặt cọc'
		FROM PHONG
		INNER JOIN inserted ON PHONG.MAPHONG = inserted.MAPHONG
	END
	
END
GO
/****** Object:  Trigger [dbo].[KIEMTRAHOPDONG_KHACHTHUE]    Script Date: 06/22/2024 3:19:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[KIEMTRAHOPDONG_KHACHTHUE]
ON [dbo].[HOPDONG]
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @MAKHACHTHUE INT, @NGAYLAP DATE, @NGAYHETHAN DATE, @MAHOPDONG VARCHAR(8)

    SELECT @MAKHACHTHUE = i.MAKHACHTHUE,
           @NGAYLAP = i.NGAYLAP,
           @NGAYHETHAN = i.NGAYHETHAN,
           @MAHOPDONG = i.MAHOPDONG
    FROM inserted i

    IF EXISTS (SELECT 1 
               FROM HOPDONG c
               WHERE c.MAKHACHTHUE = @MAKHACHTHUE
                 AND c.MAHOPDONG <> @MAHOPDONG
                 AND c.TRANGTHAIHD = N'Đang hiệu lực'
                AND ((@NGAYLAP BETWEEN c.NGAYLAP AND c.NGAYHETHAN) OR (@NGAYHETHAN BETWEEN c.NGAYLAP AND c.NGAYHETHAN)))
    BEGIN
        RAISERROR('Khách thuê này không được lập hợp đồng mới trong khi hợp đồng cũ đang hiệu lực', 16, 1)
        ROLLBACK TRANSACTION
    END
END
GO
/****** Object:  Trigger [dbo].[KIEMTRAHOPDONG_PHONG]    Script Date: 06/22/2024 3:19:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[KIEMTRAHOPDONG_PHONG]
ON [dbo].[HOPDONG]
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @MAPHONG varchar(4), @NGAYLAP DATE, @NGAYHETHAN DATE, @MAHOPDONG VARCHAR(8)

    SELECT @MAPHONG = i.MAPHONG,
           @NGAYLAP = i.NGAYLAP,
           @NGAYHETHAN = i.NGAYHETHAN,
           @MAHOPDONG = i.MAHOPDONG
    FROM inserted i

    IF EXISTS (SELECT 1 
               FROM HOPDONG c
               WHERE c.MAPHONG = @MAPHONG
                 AND c.MAHOPDONG <> @MAHOPDONG
                 AND c.TRANGTHAIHD = N'Đang hiệu lực'
                 AND ((@NGAYLAP BETWEEN c.NGAYLAP AND c.NGAYHETHAN) OR (@NGAYHETHAN BETWEEN c.NGAYLAP AND c.NGAYHETHAN)))
    BEGIN
        RAISERROR('Đã tồn tại một hợp đồng đang hiệu lực cho mã phòng này.', 16, 1)
        ROLLBACK TRANSACTION
    END
END
GO
/****** Object:  Trigger [dbo].[CAPNHATTRANGTHAITAIKHOAN]    Script Date: 06/22/2024 3:19:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[CAPNHATTRANGTHAITAIKHOAN] ON [dbo].[PHONG]
AFTER UPDATE
AS
BEGIN
	IF (UPDATE(TRANGTHAI))
	BEGIN
		DECLARE @TRANGTHAI NVARCHAR(30), @MAPHONG VARCHAR(4)
		SELECT @MAPHONG = MAPHONG,
			   @TRANGTHAI = TRANGTHAI
		FROM inserted

		UPDATE TAIKHOAN
		SET TRANGTHAI = 0
		WHERE @TRANGTHAI = N'Trống' AND MAPHONG = @MAPHONG

		UPDATE TAIKHOAN
		SET TRANGTHAI = 1
		WHERE @TRANGTHAI = N'Đã thuê' AND MAPHONG = @MAPHONG
	END
END
GO
/****** Object:  Trigger [dbo].[CHECK_ACCOUNT_OF]    Script Date: 06/22/2024 3:19:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[CHECK_ACCOUNT_OF]
ON [dbo].[TAIKHOAN]
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @MAPHONG VARCHAR(4), @MACHUTRO VARCHAR(10)
	IF (NOT UPDATE(TRANGTHAI))
	begin
	SELECT @MAPHONG = MAPHONG,
		   @MACHUTRO = MACHUTRO
	FROM inserted
	IF (@MAPHONG IS NOT NULL AND @MACHUTRO IS NOT NULL)
	BEGIN
		RAISERROR('CẢ HAI MAPHONG VÀ MACHUTRO KHÔNG ĐỒNG THỜI KHÁC NULL', 16, 1)
		ROLLBACK TRANSACTION
	END
	IF (@MAPHONG IS NULL AND @MACHUTRO IS NULL)
	BEGIN
		RAISERROR('CẢ HAI MAPHONG VÀ MACHUTRO KHÔNG ĐỒNG THỜI BẰNG NULL', 16, 2)
		ROLLBACK TRANSACTION
	END
	end
END
GO
/****** Object:  Trigger [dbo].[KICH_HOAT_TAIKHOAN]    Script Date: 06/22/2024 3:19:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[KICH_HOAT_TAIKHOAN]
ON [dbo].[TAIKHOAN]
AFTER UPDATE
AS
BEGIN
	DECLARE @TENDN NVARCHAR(50), @TRANGTHAI BIT, @MATKHAU NVARCHAR(50)
	IF (UPDATE(TRANGTHAI))
	BEGIN
		SELECT @TENDN = TENDN,
			   @MATKHAU = MATKHAU,
		       @TRANGTHAI = TRANGTHAI
		FROM inserted

		DECLARE @SQL NVARCHAR(MAX)
		IF (@TRANGTHAI = 0)
		BEGIN
			SET @SQL = 'ALTER LOGIN ' + @TENDN + ' DISABLE;'
			EXEC sp_executesql @SQL
		END
		ELSE
		BEGIN
			SET @SQL = 'ALTER LOGIN ' + @TENDN + ' ENABLE;'
			EXEC sp_executesql @SQL
		END
	END
	
END
GO
