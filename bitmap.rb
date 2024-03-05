=begin
  Bitmapの拡張
=end
class Bitmap
  class FailedToCopyMemory < StandardError; end
  
  # Bitmapファイルに保存する
  # @param [String] file 保存するファイル名
  def export(file)
    w = width
    h = height
    File.open(file, "wb") {|f|
      f.write bmp_file_header(w, h)
      f.write bmp_info_header(w, h)
      f.write bmp_color_data(w, h)
    }
  end

private
  CopyMemory_from = Win32API.new('System/itefu_bitmap.dll', 'CopyMemoryQuietly', 'ppl', 'i')


  COLOR_DEPTH_AS_BYTE = 4 # カラーデータの色深度(Byte単位)
  SIZE_OF_BMP_FILE_HEADER = 14
  SIZE_OF_BMP_INFO_HEADER = 40
  
  # BITMAPFILEHEADER
  def bmp_file_header(w, h)
    [
      "BM",
      SIZE_OF_BMP_FILE_HEADER + SIZE_OF_BMP_INFO_HEADER + w * h * COLOR_DEPTH_AS_BYTE,
      0, 0, 
      SIZE_OF_BMP_FILE_HEADER + SIZE_OF_BMP_INFO_HEADER
    ].pack("a2VvvV")
  end

  # BITMAPINFOHEADER 
  def bmp_info_header(w, h)
    [
      SIZE_OF_BMP_INFO_HEADER, w, h,
      1, COLOR_DEPTH_AS_BYTE * 8,
      0, 0, 0, 0, 0, 0
    ].pack("VVVvvVVVVVV")
  end
  
  # 画素データ
  def bmp_color_data(w, h)
    buffer = "\0" * (COLOR_DEPTH_AS_BYTE * w * h)
    if CopyMemory_from.call(buffer, address_of_color_data, buffer.size) != 0
      raise FailedToCopyMemory
    end
    buffer
  end


  SIZE_OF_POINTER = 4     # ポインター長(Byte単位)
  SIZE_OF_BASIC = 8

  # @return [Fixnum] カラーデータが格納されているアドレスを返す
=begin
  // Bitmapのデータ構造は下記の通り:

  struct Basic {
    DWORD flags;
    DWORD klass;
  };

  template<typename T>
  struct Object {
    Basic  basic;
    T *object;
  };

  template<typename T>
  struct Data {
    Basic basic;
    void *dmark;
    void *dfree;
    Object<T> *data;
  };

  struct Bitmap {
    Basic  basic;
    BitmapInfo *info;
    void    *params;
    BGRA    *data;
  };

  // 上記を前提に
  auto rdata = reinterpret_cast<Data<Bitmap>*>(object_id << 1);
  auto bitmap = rdata->data->object;
  // であるときの  bitmap->data  を返す
=end
  def address_of_color_data
    ITEFU_DEBUG_OUTPUT_NOTICE "Information: address of color data"
    ITEFU_DEBUG_OUTPUT_NOTICE " Bitmap object: 0x%x disposed:#{self.disposed?}" % (object_id * 2)
    buffer = "\0" * SIZE_OF_POINTER
    # rdata->data
    if CopyMemory_from.call(buffer, object_id * 2 + SIZE_OF_BASIC + SIZE_OF_POINTER * 2 , buffer.size) != 0
      raise FailedToCopyMemory
    end
    # bitmap = rdata->data->object
    if CopyMemory_from.call(buffer, buffer.unpack("L")[0] + SIZE_OF_BASIC, buffer.size) != 0
      raise FailedToCopyMemory
    end
    # bitmap->data
    if CopyMemory_from.call(buffer, buffer.unpack("L")[0] + SIZE_OF_BASIC + SIZE_OF_POINTER * 2 , buffer.size) != 0
      raise FailedToCopyMemory
    end
#ifdef :ITEFU_DEVELOP
    buffer.unpack("L")[0].tap {|addr|
      ITEFU_DEBUG_OUTPUT_NOTICE " Bitmap addr: 0x%x" % addr
    }
#else
    buffer.unpack("L")[0]
#endif
  end

end
