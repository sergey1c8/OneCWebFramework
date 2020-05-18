
#Область ПрограммныйИнтерфейс
Функция ВебСайтХранитсяВМакете() Экспорт
	
	Возврат Ложь;
	
КонецФункции

Функция ИспользоватьШаблонизаторPUG() Экспорт 
	
	Возврат Истина;	
	
КонецФункции

#Область ЛичныйКабинет

// Главная функция личного кабинета. Все запросы POST и GET выполняются здесь.
//
// Параметры:
//	Запрос - HTTPСервисЗапрос - запрос HTTP.
//
// Возвращаемое значение:
//	HTTPСервисОтвет - ответ HTTP.
//
Функция ОбработкаЗапроса(Запрос,ЭтоPOST) Экспорт
	
	Перем Ответ;
	
	УстановитьПривилегированныйРежим(Истина);
	
	ОтносительныйURL 	= СокрЛП(НРег(Запрос.ОтносительныйURL));
	ИмяФайла 			= Сред(ОтносительныйURL, СтрНайти(ОтносительныйURL, "/", НаправлениеПоиска.СКонца) + 1);
	Путь 				= Лев(ОтносительныйURL, СтрДлина(ОтносительныйURL) - СтрДлина(ИмяФайла));
	ПараметрыЗапроса	= Запрос.ПараметрыЗапроса;
	БазовыйURL 			= Запрос.БазовыйURL;
	
	ПараметрыЗапроса = Новый Структура;
	
	Если ЭтоPOST тогда		
		ПараметрыЗапроса = РаскодироватьСтроку(СтрЗаменить(Запрос.ПолучитьТелоКакСтроку(),"+"," "),СпособКодированияСтроки.КодировкаURL);
		МассивПараметров = СтрРазделить(ПараметрыЗапроса, "&", Истина);
		ПараметрыЗапроса =  МассивПарамертовHTTPЗапросаВСтруктуру(МассивПараметров);
	Иначе
		Для каждого Параметр из Запрос.ПараметрыЗапроса цикл
			ПараметрыЗапроса.Вставить(Параметр.Ключ,Параметр.Значение);	
		КонецЦикла;
	КонецЕсли;

	
	ОтносительныйURLПеренаправления	= "";
	
	АвторизованныйПользователь = ВебСайт_АвторизацияРегистрация.ПолучитьАвторизованногоПользователя(Запрос.Заголовки);
	
	СтруктураСтраницы 	= ПолучитьСтруктуруСтраницыОтносительногоURL(Путь, ИмяФайла);
	КодОтвета			= 200;
	
	// Если страница не найдена
	Если СтруктураСтраницы = Неопределено Тогда
		КодОтвета = 404;
		ОтносительныйURLПеренаправления = ПолучитьОтносительнуюСсылкуСтраницы404();
		Если не ЗначениеЗаполнено(ОтносительныйURLПеренаправления) Тогда
			Ответ = Новый HTTPСервисОтвет(404);
			ТипФайла = СокрЛП("text/html; charset=utf-8");
			Ответ.УстановитьТелоИзСтроки("Page not found 404", КодировкаТекста.UTF8);
			Возврат Ответ;	
		Иначе
			Возврат ВыполнитьПеренаправление(Запрос.БазовыйURL,ОтносительныйURLПеренаправления);;		
		КонецЕсли;
	КОнецЕсли;

		
	Ответ = Новый HTTPСервисОтвет(КодОтвета);
	ТипФайла = СокрЛП(СтруктураСтраницы.ТипФайла);
	Если НРег(ТипФайла) = "text/html" Или НРег(ТипФайла) = "template/pug" Тогда
		 ТипФайла = "text/html; charset=utf-8";
		 //Проверка авторизации
		 ЕстьАвторизация = ВебСайт_АвторизацияРегистрация.ВПроектеЕстьАвторизация();
		 Если ЕстьАвторизация и не ЗначениеЗаполнено(АвторизованныйПользователь) и не (СтруктураСтраницы.СтраницаАвторизации
			 или СтруктураСтраницы.СтраницаДоступноБезАвторизации или СтруктураСтраницы.Страница404) тогда			 
			 ОтносительныйURLПеренаправления = ВебСайт_АвторизацияРегистрация.ПолучитьОтносительнуюСсылкуСтраницыАвторизации();
			 Возврат ВыполнитьПеренаправление(Запрос.БазовыйURL,ОтносительныйURLПеренаправления);
		 КонецЕсли;
		 
	КонецЕсли;
	Ответ.Заголовки.Вставить("Content-Type", ТипФайла);
	Если Найти(ТипФайла, "image") > 0 Тогда
		Ответ.Заголовки.Вставить("Cache-Control", "max-age=31536000"); // Рисунки надо кэшировать браузером	
	КонецЕсли;
	
	
	Данные = СтруктураСтраницы.ХранилищеФайла.Получить(); 
	Переменные = Новый Структура;
	Переменные.Вставить("БазовыйURL", 	БазовыйURL);
	Переменные.Вставить("BASE_URL", 	БазовыйURL);	
	
	Если СтрНайти(НРег(ТипФайла), "text/") = 0 Тогда
		
		Если ПустаяСтрока(СтруктураСтраницы.АлгоритмОбработки) Тогда
			
			Ответ.УстановитьТелоИзДвоичныхДанных(Данные);
			
		Иначе
			
			Тело = Неопределено;
			ВебСайт_Шаблонизатор.ВыполнитьАлгоритм(Тело, Переменные, Запрос, Ответ, ОтносительныйURL, ОтносительныйURLПеренаправления, ИмяФайла, Путь, СтруктураСтраницы.АлгоритмОбработки, ЭтоPOST, ПараметрыЗапроса,АвторизованныйПользователь);
			Если Тело <> Неопределено Тогда
				Ответ.УстановитьТелоИзДвоичныхДанных(Тело);
			КонецЕсли;                 
			                  
		КонецЕсли;
		
	Иначе
		
				
		Тело = ПолучитьТекстИзДвоичныхДанных(Данные);
		ВебСайт_Шаблонизатор.ВставитьВТелоШаблоны(Тело, Переменные, Запрос, Ответ, ОтносительныйURL, ОтносительныйURLПеренаправления, ИмяФайла, Путь, СтруктураСтраницы.АлгоритмОбработки, ЭтоPOST, ПараметрыЗапроса,АвторизованныйПользователь);
		
		// Надо нормальными сделать переменные (чтобы не содержали спец символов HTML).
		Для Каждого Стр Из Переменные Цикл
			Если ТипЗнч(Стр.Значение) = Тип("Строка") Тогда
				Переменные[Стр.Ключ] = СтрЗаменить(Переменные[Стр.Ключ], "<", "&lt;");
				Переменные[Стр.Ключ] = СтрЗаменить(Переменные[Стр.Ключ], ">", "&gt;");
			КонецЕсли;
		КонецЦикла;
		
		ВебСайт_Шаблонизатор.ВставитьВТелоПараметры(Тело, Переменные, Запрос, Ответ, ОтносительныйURL, ОтносительныйURLПеренаправления, ИмяФайла, Путь, СтруктураСтраницы.АлгоритмОбработки, ЭтоPOST, ПараметрыЗапроса,АвторизованныйПользователь);
		
		// Перенаправляем на другую страницу.
		// Тут надо быть внимательным, чтобы не было рекурсии.
		Если НЕ ПустаяСтрока(ОтносительныйURLПеренаправления) Тогда
			Возврат ВыполнитьПеренаправление(Запрос.БазовыйURL,ОтносительныйURLПеренаправления);
		Иначе
			// Проверка на то, что есть системные переменные.
			Ответ.УстановитьТелоИзСтроки(Тело, КодировкаТекста.UTF8);
		КонецЕсли;
		
	КонецЕсли;
		
	Возврат Ответ;
		
КонецФункции

#КонецОбласти

#Область ВспомогательныеФункции

Функция ВыполнитьПеренаправление(БазовыйURL,ОтносительныйURLПеренаправления)
	
	Ответ = Новый HTTPСервисОтвет(302);
	Ответ.Заголовки.Очистить();
	НовыйURL = СокрЛП(БазовыйURL) + "/" + ОтносительныйURLПеренаправления;
	Ответ.Заголовки.Вставить("Location", НовыйURL);
	Ответ.Заголовки.Вставить("Content-Location", НовыйURL);
	Возврат Ответ;		

КонецФункции

// Находит в справочнике "ЛичныйКабинет" элемент в нужной иерархии папок 
// 	и для данного элемента.
//
// Параметры:
//	Путь - Строка - исходный путь.
//	ИмяФайла - Строка - имя файла.
//
// Возвращаемое значение:
//	Структура("ТипФайла,АлгоритмОбработки,ХранилищеФайла,СтраницаАвторизации,СтраницаДоступноБезАвторизации,Страница404,СтраницаОсновная") - описание найденной страницы, либо Неопределено.
Функция ПолучитьСтруктуруСтраницыОтносительногоURL(Знач Путь, Знач ИмяФайла) Экспорт
	
	НужнаОбработкаPUG = Ложь;
	
	Если ВебСайтХранитсяВМакете() тогда
		Возврат Обработки.ВебСайт_Шаблоны.ВернутьHTMLПоОтносительнойСсылке(Путь,ИмяФайла);
	КонецЕсли;
	
	СтруктураСтраницы = Новый Структура("ТипФайла,АлгоритмОбработки,ХранилищеФайла,СтраницаАвторизации,СтраницаДоступноБезАвторизации,Страница404,СтраницаОсновная");
	
	Если ПустаяСтрока(ИмяФайла) Тогда
		ИмяФайла = ПолучитьОтносительнуюСсылкуОсновнойСтраницы();
	КонецЕсли;
	
	Массив 				= РазложитьСтрокуВМассивПодстрок(Путь, "/", Истина, Истина);	
	МассивРодителей 	= Новый Массив();
	ТекстРодители		= "";
	Запрос 				= Новый Запрос();
	
	ТекстЗапроса = 
		"ВЫБРАТЬ ПЕРВЫЕ 1
		|	Страницы.Ссылка КАК Страница,
		|	Страницы.ТипФайла КАК ТипФайла,
		|	Страницы.АлгоритмОбработки КАК АлгоритмОбработки,
		|	Страницы.ХранилищеФайла КАК ХранилищеФайла,
		|	Страницы.СтраницаАвторизации КАК СтраницаАвторизации,
		|	Страницы.СтраницаДоступноБезАвторизации КАК СтраницаДоступноБезАвторизации,
		|	Страницы.Страница404 КАК Страница404,
		|	Страницы.СтраницаОсновная КАК СтраницаОсновная
		|ИЗ
		|	Справочник.ВебСайт КАК Страницы
		|ГДЕ
		|	Страницы.Наименование = &ИмяФайла
		|	И НЕ Страницы.ПометкаУдаления";
	
	Если ИспользоватьШаблонизаторPUG() Тогда
		Если СтрНайти(ИмяФайла, "html") > 0 Тогда
			НужнаОбработкаPUG = Истина; 
			ИмяФайла = СтрЗаменить(ИмяФайла, "html", "pug");
		КонецЕсли;		
	КонецЕсли;	
	
	Запрос.УстановитьПараметр("ИмяФайла", ИмяФайла);
	
	Индекс = Массив.Количество() - 1;
	Пока Индекс >= 0 Цикл
		
		Файл = Массив[Индекс];
		
		Если Файл = "." Тогда
			Индекс = Индекс - 1;
			Продолжить;
		ИначеЕсли Файл = ".." Тогда
			Если МассивРодителей.Количество() > 0 Тогда
				МассивРодителей.Удалить(МассивРодителей.Количество()  -1);
			КонецЕсли;
			ТекстРодители = ТекстРодители + ".Родитель";
		КонецЕсли;
		
		ТекстРодители = ТекстРодители + ".Родитель";
		ТекстЗапроса = ТекстЗапроса + Символы.ПС + Символы.Таб 
			+ "И Страницы" + ТекстРодители + ".Наименование=&Файл" + Формат(Индекс, "ЧРД=; ЧРГ=; ЧН=0; ЧГ=");
		Запрос.УстановитьПараметр("Файл" + Формат(Индекс, "ЧРД=; ЧРГ=; ЧН=0; ЧГ="), Файл);
		
		МассивРодителей.Добавить(Файл);
		Индекс = Индекс - 1;
	КонецЦикла;
	
	Если МассивРодителей.Количество() = 0 Тогда
		ТекстЗапроса = ТекстЗапроса + Символы.ПС + Символы.Таб 
			+ "И Страницы.Родитель=&ПустойРодитель";
		Запрос.УстановитьПараметр("ПустойРодитель", Справочники.ВебСайт.ПустаяСсылка());
	КонецЕсли;
		
	Запрос.Текст = ТекстЗапроса;
	
	Выборка = Запрос.Выполнить().Выбрать();
	Если Выборка.Следующий() Тогда
		//Возврат Выборка.Ссылка;
		ЗаполнитьЗначенияСвойств(СтруктураСтраницы,Выборка);
		Если НужнаОбработкаPUG Тогда
			СтруктураСтраницы.ХранилищеФайла = ВебСайт_ШаблонизаторPug.ПолучитьHTMLСтраницу(Выборка.Страница); 		
		КонецЕсли;		
		Возврат СтруктураСтраницы;		
	КонецЕсли;
	
	Возврат Неопределено;

КонецФункции

Функция ПолучитьОтносительнуюСсылкуСтраницы404() Экспорт
	
	Если ВебСайтХранитсяВМакете() тогда
		Возврат Обработки.ВебСайт_Шаблоны.ПолучитьОтносительнуюСсылкуСтраницыАвторизации();
	КонецЕсли;
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	ВебСайт.ОтносительнаяСсылка КАК ОтносительнаяСсылка
	|ИЗ
	|	Справочник.ВебСайт КАК ВебСайт
	|ГДЕ
	|	ВебСайт.Страница404";
	Выборка = Запрос.Выполнить().Выбрать();
	Пока Выборка.Следующий() цикл
		Возврат Выборка.ОтносительнаяСсылка;
	КонецЦикла;
	
	Возврат "";
	
КонецФункции

Функция ПолучитьОтносительнуюСсылкуОсновнойСтраницы() Экспорт
	
	Если ВебСайтХранитсяВМакете() тогда
		Возврат Обработки.ВебСайт_Шаблоны.ПолучитьОтносительнуюСсылкуОсновнойСтраницы();
	КонецЕсли;

	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	ВебСайт.ОтносительнаяСсылка КАК ОтносительнаяСсылка
	|ИЗ
	|	Справочник.ВебСайт КАК ВебСайт
	|ГДЕ
	|	ВебСайт.СтраницаОсновная";
	Выборка = Запрос.Выполнить().Выбрать();
	Пока Выборка.Следующий() цикл
		Если СтрНайти(Выборка.ОтносительнаяСсылка,".pug") Тогда 
			Возврат СтрЗаменить(Выборка.ОтносительнаяСсылка,".pug",".html");
		Иначе 
			Возврат Выборка.ОтносительнаяСсылка;
		КонецЕсли;
	КонецЦикла;
	
	Возврат "";
	
КонецФункции

Функция МассивПарамертовHTTPЗапросаВСтруктуру(МассивПараметров) Экспорт
	
	ПараметрыЗапроса = Новый Структура;
	Для каждого ПараметрЭлемент из МассивПараметров цикл	
		Если не ЗначениеЗаполнено(ПараметрЭлемент) тогда
			Продолжить;
		КонецЕсли;
		НомерСимволаРазделителя = СтрНайти(ПараметрЭлемент,"=");
		ПараметрИмя = Лев(ПараметрЭлемент,НомерСимволаРазделителя-1);
		Значение = Сред(ПараметрЭлемент,НомерСимволаРазделителя+1);
		ПараметрыЗапроса.Вставить(ПараметрИмя,Значение);		
	КонецЦикла;
	
	Возврат ПараметрыЗапроса;
	
КонецФункции

// Получает текст из двоичных данных.
//
// Параметры:
//	
//
// Возвращаемое значение:
//	
//
Функция ПолучитьТекстИзДвоичныхДанных(Знач Данные) Экспорт
	
	Если ТипЗнч(Данные) = Тип("Строка") Тогда
		Возврат Данные;
	ИначеЕсли ТипЗнч(Данные) <> Тип("ДвоичныеДанные") Тогда
		Возврат "";
	КонецЕсли;
	
    Возврат ПолучитьСтрокуИзДвоичныхДанных(Данные);
	
КонецФункции

// Разбивает строку на несколько строк по указанному разделителю. Разделитель может иметь любую длину.
// В случаях, когда разделителем является строка из одного символа, и не используется параметр СокращатьНепечатаемыеСимволы,
// рекомендуется использовать функцию платформы СтрРазделить.
//
// Параметры:
//  Значение               - Строка - текст с разделителями;
//  Разделитель            - Строка - разделитель строк текста, минимум 1 символ;
//  ПропускатьПустыеСтроки - Булево - признак необходимости включения в результат пустых строк.
//    Если параметр не задан, то функция работает в режиме совместимости со своей предыдущей версией:
//     - для разделителя-пробела пустые строки не включаются в результат, для остальных разделителей пустые строки
//       включаются в результат;
//     - если параметр Строка не содержит значащих символов или не содержит ни одного символа (пустая строка), то в
//       случае разделителя-пробела результатом функции будет массив, содержащий одно значение "" (пустая строка), а
//       при других разделителях результатом функции будет пустой массив.
//  СокращатьНепечатаемыеСимволы - Булево - сокращать непечатаемые символы по краям каждой из найденных подстрок.
//
// Возвращаемое значение:
//  Массив - массив строк.
//
// Пример:
//  СтроковыеФункцииКлиентСервер.РазложитьСтрокуВМассивПодстрок(",один,,два,", ",")
//  - возвратит массив из 5 элементов, три из которых  - пустые: "", "один", "", "два", "";
//  СтроковыеФункцииКлиентСервер.РазложитьСтрокуВМассивПодстрок(",один,,два,", ",", Истина)
//  - возвратит массив из двух элементов: "один", "два";
//  СтроковыеФункцииКлиентСервер.РазложитьСтрокуВМассивПодстрок(" один   два  ", " ")
//  - возвратит массив из двух элементов: "один", "два";
//  СтроковыеФункцииКлиентСервер.РазложитьСтрокуВМассивПодстрок("")
//  - возвратит пустой массив;
//  СтроковыеФункцииКлиентСервер.РазложитьСтрокуВМассивПодстрок("",,Ложь)
//  - возвратит массив с одним элементом: ""(пустая строка);
//  СтроковыеФункцииКлиентСервер.РазложитьСтрокуВМассивПодстрок("", " ")
//  - возвратит массив с одним элементом: "" (пустая строка).
//
Функция РазложитьСтрокуВМассивПодстрок(Знач Значение, Знач Разделитель = ",", Знач ПропускатьПустыеСтроки = Неопределено, 
	СокращатьНепечатаемыеСимволы = Ложь) Экспорт
	
	Если Разделитель = "," 
		И ПропускатьПустыеСтроки = Неопределено 
		И СокращатьНепечатаемыеСимволы Тогда 
		
		Результат = СтрРазделить(Значение, ",", Ложь);
		Для Индекс = 0 По Результат.ВГраница() Цикл
			Результат[Индекс] = СокрЛП(Результат[Индекс])
		КонецЦикла;
		Возврат Результат;
		
	КонецЕсли;
	
	Результат = Новый Массив;
	
	// Для обеспечения обратной совместимости.
	Если ПропускатьПустыеСтроки = Неопределено Тогда
		ПропускатьПустыеСтроки = ?(Разделитель = " ", Истина, Ложь);
		Если ПустаяСтрока(Значение) Тогда 
			Если Разделитель = " " Тогда
				Результат.Добавить("");
			КонецЕсли;
			Возврат Результат;
		КонецЕсли;
	КонецЕсли;
	//
	
	Позиция = СтрНайти(Значение, Разделитель);
	Пока Позиция > 0 Цикл
		Подстрока = Лев(Значение, Позиция - 1);
		Если Не ПропускатьПустыеСтроки Или Не ПустаяСтрока(Подстрока) Тогда
			Если СокращатьНепечатаемыеСимволы Тогда
				Результат.Добавить(СокрЛП(Подстрока));
			Иначе
				Результат.Добавить(Подстрока);
			КонецЕсли;
		КонецЕсли;
		Значение = Сред(Значение, Позиция + СтрДлина(Разделитель));
		Позиция = СтрНайти(Значение, Разделитель);
	КонецЦикла;
	
	Если Не ПропускатьПустыеСтроки Или Не ПустаяСтрока(Значение) Тогда
		Если СокращатьНепечатаемыеСимволы Тогда
			Результат.Добавить(СокрЛП(Значение));
		Иначе
			Результат.Добавить(Значение);
		КонецЕсли;
	КонецЕсли;
	
	Возврат Результат;
	
КонецФункции

#КонецОбласти

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

#Область Кодировки

// Функции по преобразованию Base <=> Текстовая строка
Процедура УдалитьПрефиксUTF(Строка64)
	
	Если Лев(Строка64, 4) = "77u/" Тогда Строка64 = Сред(Строка64, 5); КонецЕсли;
	
КонецПроцедуры

Функция Строка64ВСтроку(Знач Строка64)
	
	Если Лев(Строка64, 4) = "77u/" Тогда 
		Строка64 = Сред(Строка64, 5); 
	КонецЕсли;
	                    
	Массив64 = Новый Массив;
	Для Код = КодСимвола("A") По КодСимвола("Z") Цикл 
		Массив64.Добавить(Символ(Код)); 
	КонецЦикла;
	Для Код = КодСимвола("a") По КодСимвола("z") Цикл 
		Массив64.Добавить(Символ(Код)); 
	КонецЦикла;
	Для Код = КодСимвола("0") По КодСимвола("9") Цикл 
		Массив64.Добавить(Символ(Код)); 
	КонецЦикла;
	Массив64.Добавить("+");
	Массив64.Добавить("/");
	
	МассивВрем = Новый Массив;
	
	Строка64 = СтрЗаменить(СтрЗаменить(Строка64, Символ(13), ""), Символ(10), "");

	Количество4 = Цел(СтрДлина(Строка64) / 4);
	Рет 		= "";
	Загрушек 	= 0;
	Для Индекс4 = 0 По Количество4 - 1 Цикл
		Накопитель = 0;
		Для Индекс = 0 По 3 Цикл
			Символ = Сред(Строка64, Индекс4 * 4 + 1 + Индекс, 1);
			Если Символ = "=" Тогда 
				Загрушек = Загрушек + 1;
				Накопитель = Накопитель * 64;
				Продолжить;
			КонецЕсли;
			
			ИндексЭлемента = Массив64.Найти(Символ);
			Накопитель = Накопитель * 64 + ИндексЭлемента;
		КонецЦикла;
		
		Для Индекс3 = - 2 По 0 Цикл
			Остаток = Накопитель % 256;
			Если МассивВрем.ВГраница() >= Индекс4 * 3 - Индекс3 Тогда
				МассивВрем[Индекс4 * 3 - Индекс3] = Остаток;
			Иначе
				МассивВрем.Вставить(Индекс4 * 3 - Индекс3, Остаток);
			КонецЕсли;
			Накопитель = (Накопитель - Остаток) / 256;
		КонецЦикла;
	КонецЦикла;
		
	КоличествоЭлементов = МассивВрем.Количество() - Загрушек;
	Индекс = 0;
	Пока Индекс < КоличествоЭлементов Цикл
		Если Индекс + 3 < КоличествоЭлементов И МассивВрем[Индекс] >= 240 И МассивВрем[Индекс + 1] >= 128 И МассивВрем[Индекс + 2] >= 128 И МассивВрем[Индекс + 3] >= 128 Тогда
			Рет = Рет + Символ(64 * 64 * 64 *(МассивВрем[Индекс] - 240) + 64 * 64 *(МассивВрем[Индекс + 1]) - 128 + 64 * (МассивВрем[Индекс + 2] - 128) + МассивВрем[Индекс + 3] - 128);
			Индекс = Индекс + 4;
			Продолжить;
		ИначеЕсли Индекс + 2 < КоличествоЭлементов И МассивВрем[Индекс] >= 224 И МассивВрем[Индекс + 1] >= 128 И МассивВрем[Индекс + 2] >= 128 Тогда
			Рет = Рет + Символ(64 * 64 * (МассивВрем[Индекс] - 224) + 64 * (МассивВрем[Индекс + 1] - 128) + МассивВрем[Индекс + 2] - 128);
			Индекс = Индекс + 3;
			Продолжить;
		ИначеЕсли Индекс + 1 < КоличествоЭлементов И МассивВрем[Индекс] >= 192 И МассивВрем[Индекс + 1] >= 128 Тогда
			Рет = Рет + Символ(64 * (МассивВрем[Индекс] - 192) + МассивВрем[Индекс + 1] - 128);
			Индекс = Индекс + 2;
			Продолжить;
		Иначе	
			Рет = Рет + Символ(МассивВрем[Индекс]);
			Индекс = Индекс + 1;
			Продолжить;
		КонецЕсли;
	КонецЦикла;
	Рет = СтрЗаменить(Рет, Символы.ВК + Символы.ПС, Символы.ПС);
	
	Возврат Рет;
	
КонецФункции

// Преобразует символ в юникод.
//
// Параметры:
//	Символ - Строка - символ.
//
// Возвращаемое значение:
//	Строка - в формате юникод.
//
Функция ПреобразоватьСимволЮникод(Знач Символ)
	
	Код = КодСимвола(Символ);
	
	Если Код >= 2048 Тогда
		КоличествоБайт = 2;
		Байты = Новый Массив; Байты.Добавить(224); Байты.Добавить(128); Байты.Добавить(128);
	ИначеЕсли Код >= 128 Тогда
		КоличествоБайт = 1;
		Байты = Новый Массив; Байты.Добавить(192); Байты.Добавить(128); 
	Иначе
		Байты = Новый Массив; Байты.Добавить(Код);
		Возврат Байты;
	КонецЕсли;	
	
	Для ИндексБайт = - КоличествоБайт По 0 Цикл
		Остаток = (Код % 64);
		Байты[- ИндексБайт] = Байты[- ИндексБайт] + Остаток;
		Код = (Код - Остаток) / 64;
	КонецЦикла;
	
    Возврат Байты;
	
КонецФункции

Функция СтрокаВСтроку64(Знач СтрокаСимволов)
	
	Массив64 = Новый Массив;
	
	Для Код = КодСимвола("A") По КодСимвола("Z") Цикл 
		Массив64.Добавить(Символ(Код)); 
	КонецЦикла;
	Для Код = КодСимвола("a") По КодСимвола("z") Цикл 
		Массив64.Добавить(Символ(Код)); 
	КонецЦикла;
	Для Код = КодСимвола("0") По КодСимвола("9") Цикл 
		Массив64.Добавить(Символ(Код)); 
	КонецЦикла;
	Массив64.Добавить("+");
	Массив64.Добавить("/");

	Рет = "";   
	РетХ = "";
	СтрокаСимволов = СтрЗаменить(СтрокаСимволов, Символы.ПС, Символы.ВК + Символы.ПС);
	КоличествоСимволов = СтрДлина(СтрокаСимволов);
	
	КоличествоУчтенных = 0;
	Накопитель = 0;
	Для Индекс = 0 По КоличествоСимволов - 1 Цикл
		МассивВрем = ПреобразоватьСимволЮникод(Сред(СтрокаСимволов, Индекс + 1, 1));
		
		Для ИндексВ = 0 По МассивВрем.Количество() - 1 Цикл
			Накопитель = Накопитель * 256 + МассивВрем[ИндексВ];
			Если КоличествоУчтенных = 2 ИЛИ (Индекс = КоличествоСимволов - 1 И ИндексВ = МассивВрем.Количество() - 1) Тогда
				Пока КоличествоУчтенных < 2 Цикл 
					Накопитель = Накопитель * 256; 
					КоличествоУчтенных = КоличествоУчтенных + 1; 
					РетХ = РетХ + "="; 
				КонецЦикла;
				МассивГрупп = Новый Массив(4);
				Для Индекс4 = -3 По 0 Цикл
					Остаток = Накопитель % 64;
					Накопитель = (Накопитель - Остаток) / 64;
					МассивГрупп[ - Индекс4] = Остаток;
				КонецЦикла;
				Для Индекс4 = 0 По 3 Цикл 
					Рет = Рет + Массив64[МассивГрупп[Индекс4]];
				КонецЦикла;	
				КоличествоУчтенных = 0;
			Иначе
				КоличествоУчтенных = КоличествоУчтенных + 1;
			КонецЕсли
		КонецЦикла;
	КонецЦикла;
	
	Возврат "77u/" + ?(ЗначениеЗаполнено(РетХ), Лев(Рет, СтрДлина(Рет) - СтрДлина(РетХ)) + РетХ, Рет);
	
КонецФункции

// Из структуры POST по ключу найти значение.
//
// Параметры:
//	POST - Структура - исходная структура.
//	Ключ - Строка - ключ в структуре.
//
// Возвращаемое значение:
//	Произвольные - значение по ключу.
//
Функция ЗначениеPOST(Знач POST, Знач Ключ)
	
	нКлюч = НРег(СокрЛП(Ключ));
	
	Для Каждого Структура Из POST Цикл
		Если НРег(СокрЛП(Структура.Имя)) = нКлюч Тогда
			Возврат Структура.Значение;
		КонецЕсли;
	КонецЦикла;
	
	Возврат Неопределено;
	
КонецФункции

// Из структуры POST по ключу найти имя файла.
//
// Параметры:
//	POST - Структура - исходная структура.
//	Ключ - Строка - ключ в структуре.
//
// Возвращаемое значение:
//	Произвольные - имя файла по ключу.
//
Функция ИмяФайлаPOST(Знач POST, Знач Ключ)
	
	нКлюч = НРег(СокрЛП(Ключ));
	
	Для Каждого Структура Из POST Цикл
		Если НРег(СокрЛП(Структура.Имя)) = нКлюч Тогда
			Возврат Структура.ИмяФайла;
		КонецЕсли;
	КонецЦикла;
	
	Возврат Неопределено;
	
КонецФункции

//Возвращает строку - кодированные по Base64 данные, представленные массивом байт
Функция КодироватьБ64(Знач Данные)
    
	Б64т = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
	Б64м = Новый Массив(64);
	Для НН = 0 По 63 Цикл
		Б64м[НН] = Сред(Б64т, НН + 1, 1);
	КонецЦикла;
	Рез = "";
	Кол = Данные.Количество();
	Для НН = 0 По Цел(Кол / 3) - 1 цикл
		Рез = Рез + Б64м[Цел(Данные[НН * 3] / 4)]                                          
		  + Б64м[(Данные[НН * 3] % 4) * 16 + Цел(Данные[НН * 3 + 1] / 16)]
		  + Б64м[(Данные[НН * 3 + 1] % 16) * 4 + Цел(Данные[НН * 3 + 2] / 64)]
		  + Б64м[(Данные[НН * 3 + 2] % 64)];
      КонецЦикла;
      
    о = Кол % 3;
	Если о > 0 тогда
		НН = Цел(Кол / 3) * 3;
		ч1 = Данные[НН];
		ч2 = ?(о > 1, Данные[НН+1], 0);
		Рез = Рез + Б64м[Цел(ч1 / 4)] + Б64м[(ч1 % 4) * 16 + Цел(ч2 / 16)];
		Если о = 1 тогда
			Рез = Рез + "==";
		Иначе
			Рез = Рез + Б64м[(ч2 % 16) * 4] + "=";
		КонецЕсли;
    КонецЕсли;
    
	Возврат Рез;
    
КонецФункции

//Возвращает массив чисел - байт, декодированных из Base64 строки
Функция ДекодироватьБ64(Знач ИсходнаяСтрока)
    
	Б64т = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	Б64м = Новый Массив(64);
	Для НН = 0 По 63 Цикл
		Б64м[НН] = Сред(Б64т, НН + 1, 1);
    КонецЦикла;
    
	Рез = Новый Массив;
	Для СтрИ = 1 По СтрЧислоСтрок(ИсходнаяСтрока) Цикл
		стр = СтрПолучитьСтроку(ИсходнаяСтрока, СтрИ);
		Для Н=1 По Цел(СтрДлина(стр)/4) Цикл
			с1 = Сред(стр,(Н-1) * 4 + 1, 1);
			с2 = Сред(стр,(Н-1) * 4 + 2, 1);
			с3 = Сред(стр,(Н-1) * 4 + 3, 1);
			с4 = Сред(стр,(Н-1) * 4 + 4, 1);
			к1 = СтрНайти(Б64т, с1) - 1;
			к2 = СтрНайти(Б64т, с2) - 1;
			к3 = СтрНайти(Б64т, с3) - 1;
			к4 = СтрНайти(Б64т, с4) - 1;
			Если (к1 < 0) ИЛИ (к2 < 0) тогда
				Возврат рез;
			КонецЕсли;
			Рез.Добавить(к1 * 4 + Цел(к2/16));
			Если к3 >= 0 тогда
				Рез.Добавить((к2 % 16) * 16 + Цел(к3 / 4));
			Иначе
				Возврат Рез;
			КонецЕсли;
			Если к4 >= 0 тогда
				Рез.Добавить((к3 % 4) * 64 + к4);
			Иначе
				Возврат Рез;
			КонецЕсли;
        КонецЦикла;
        
		Если СтрДлина(стр) % 4 > 0 Тогда
			Прервать;
        КонецЕсли;
        
    КонецЦикла;
    
	Возврат Рез;
    
КонецФункции

#КонецОбласти

#Область ДляОбработкиПолученияМультиданныхPOST

Функция ПолучитьТокен64(Знач Токен, Хвост = 0)
	
	СтрДл = СтрДлина(Токен);
	Хвост = СтрДл % 3;
	СтрДл = СтрДл - Хвост;
	Ответ = СтрокаВСтроку64(Лев(Токен, СтрДл));
	УдалитьПрефиксUTF(Ответ);
	
	Возврат Ответ;
	
КонецФункции

Функция ПолучитьИнфоПоКонтенту(Знач тЗаголовок) 
	
	//Content-Disposition: form-data; name="comment"
	//Content-Disposition: form-data; name="upload1"; filename="IMG_20150108_163648.jpg"
	//Content-Type: image/jpeg
	
	Ответ = Новый Соответствие;
    
	Для сч1 = 1 по СтрЧислоСтрок(тЗаголовок) Цикл
		тСтр1 = СтрЗаменить(СокрЛП(СтрПолучитьСтроку(тЗаголовок, сч1)), ";", Символы.ПС);
		Для сч2 = 1 по СтрЧислоСтрок(тСтр1) Цикл
			тСтр = СокрЛП(СтрПолучитьСтроку(тСтр1, сч2));
			Если Лев(НРег(тСтр), 13)="content-type:" Тогда
				Ответ.Вставить("content-type", СокрЛ(Сред(тСтр, 14)));
				Продолжить;
			КонецЕсли;
			П = СтрНайти(тСтр, "=");
			Если П > 0 Тогда
				ТекЗнач = СокрЛП(Сред(тСтр, П+1));
				Если Лев(ТекЗнач, 1) = """" И Прав(ТекЗнач, 1) = """" Тогда
					ТекЗнач = Сред(ТекЗнач, 2, СтрДлина(ТекЗнач)-2);
				КонецЕсли;
				Ответ.Вставить(НРег(СокрЛП(Лев(тСтр, П - 1))), ТекЗнач);
			КонецЕсли;
		КонецЦикла;
	КонецЦикла;
	
	Возврат Ответ;
	
КонецФункции

// Возвращает массив структур (Тип,Имя,ИмяФайла,Значение)
Функция РазобратьКонтентHTML(ДД, Знач Токен) 
	
	Ответ = Новый Массив;
	
	НачальнаяДлинаТокена = СтрДлина(Токен);
	Данные = СтрЗаменить(СтрЗаменить(СтрЗаменить(СтрЗаменить(Base64Строка(ДД), Символы.ПС, ""), Символы.ВК, ""), Символы.ПФ, ""), Символы.Таб, "");
	УдалитьПрефиксUTF(Данные);	
	
	Токен1 		 = ПолучитьТокен64(Токен);
	Токен2 		 = ПолучитьТокен64(Сред(Токен, 2));
	Токен3 		 = ПолучитьТокен64(Сред(Токен, 3));
	ДлинаТокена1 = СтрДлина(Токен1);
	ДлинаТокена2 = СтрДлина(Токен2);
	ДлинаТокена3 = СтрДлина(Токен3);
	
	
	Предел 		= СтрДлина(Данные);	
	П 			= СтрНайти(Данные, Токен1);
	ДлинаТокена = ДлинаТокена1;
	ПрефиксТокена = 0;
	Пока (П > 0) И (П < Предел) Цикл
		ТекЧасть = Лев(Данные, П-1);
		Данные = Сред(Данные, П + ДлинаТокена);		
		
		Если ТекЧасть<>"" Тогда
			тЗаголовок = Строка64ВСтроку(Лев(ТекЧасть, 1020));
			П = СтрНайти(тЗаголовок, Символы.ПС + Символы.ПС);
			Если П > 0 Тогда
				тЗаголовок 	= Лев(тЗаголовок, П+2);				
				тЗаг 		= СокрЛП(Сред(тЗаголовок, СтрНайти(тЗаголовок, Символы.ПС)+1));				
				ТекИнфо 	= ПолучитьИнфоПоКонтенту(тЗаг);
				тТип 		= ТекИнфо["content-type"]; 
				тТип 		= ?(тТип = Неопределено, "", тТип);
				тФайл 		= ТекИнфо["filename"]; 
				тФайл 		= ?(тФайл = Неопределено, "", тФайл);
				тИмяПоля 	= ТекИнфо["name"]; 
				тИмяПоля 	= ?(тИмяПоля = Неопределено, "", тИмяПоля);
				Если (тТип = "" ИЛИ НРег(Лев(тТип, 5)) = "text/") И (тФайл="") Тогда
					Содержимое = Строка64ВСтроку(ТекЧасть);
					Содержимое = Сред(Содержимое, СтрНайти(Содержимое, Символы.ПС + Символы.ПС) + 2);
					Содержимое = Лев(Содержимое, СтрДлина(Содержимое) - ПрефиксТокена);
					Ответ.Добавить(Новый Структура("Тип,Имя,ИмяФайла,Значение", "text", тИмяПоля, тФайл, Содержимое));
				Иначе
					дл64 = 4;
					тЗаголовок = Строка64ВСтроку(Лев(ТекЧасть, дл64));
					П = СтрНайти(тЗаголовок, Символы.ПС+Символы.ПС);
					Пока П=0 И дл64<1000 Цикл
						дл64 = дл64 + 4;
						тЗаголовок = Строка64ВСтроку(Лев(ТекЧасть, дл64));
						П = СтрНайти(тЗаголовок, Символы.ПС + Символы.ПС);
					КонецЦикла;
					П = П + 2;
					Часть1 = ДекодироватьБ64(Прав(Лев(ТекЧасть, дл64), 4));
					Если Часть1.Количество() = 3 Тогда
						Для сч = 0 по 2 Цикл
							Если Часть1[0] = 13 или Часть1[0] = 10 Тогда
								Часть1.Удалить(0);
							Иначе
								Прервать;
							КонецЕсли;
						КонецЦикла;
					Иначе
						Часть1.Очистить();
					КонецЕсли;
					Если Часть1.Количество()=0 Тогда
						Часть1 = Неопределено;
					Иначе
						Часть1 = Base64Значение(КодироватьБ64(Часть1));
					КонецЕсли;
					тТело = Сред(ТекЧасть, дл64+1);
					ДД = Base64Значение(тТело);
					Если ДД <> Неопределено Тогда
						Если Часть1 <> Неопределено Тогда
							ДД = ОбъединитьДвоичныеДаннные(Часть1, ДД);
						КонецЕсли;
						Ответ.Добавить(Новый Структура("Тип, Имя, ИмяФайла, Значение", тТип, тИмяПоля, тФайл, ДД) );
					КонецЕсли;
				КонецЕсли;
			КонецЕсли;
		КонецЕсли;
		
		П1 = СтрНайти(Данные, Токен1);
		П2 = СтрНайти(Данные, Токен2);
		П3 = СтрНайти(Данные, Токен3);
		Если П1 = 0 И П2 = 0 И П3 = 0 Тогда
			Прервать;
		Иначе
			П1 	= ?(П1 = 0, Предел, П1);
			П2 	= ?(П2 = 0, Предел, П2);
			П3 	= ?(П3 = 0, Предел, П3);
			П 	= Мин(П1, П2, П3);
			ДлинаТокена 	= ?(П = П1, ДлинаТокена1, ?(П = П2, ДлинаТокена2, ДлинаТокена3));
			ПрефиксТокена 	= ?(П = П1, 0, ?(П=П2, 1, 2));
		КонецЕсли;
	КонецЦикла;
	
	Возврат Ответ;
КонецФункции

#КонецОбласти


// Объединение двоичных данных в одни двоичные данные.
//
// Параметры:
//	ДД1 - ДвоичныеДанные - что надо объединить.
//	ДД2 - ДвоичныеДанные - что надо объединить.
//	ДД3 - ДвоичныеДанные - что надо объединить.
//	ДД4 - ДвоичныеДанные - что надо объединить.
//	ДД5 - ДвоичныеДанные - что надо объединить.
//	ДД6 - ДвоичныеДанные - что надо объединить.
//	ДД7 - ДвоичныеДанные - что надо объединить.
//
// Возвращаемое значение:
//	ДвоичныеДанные - результат объединения.
//
Функция ОбъединитьДвоичныеДаннные(ДД1, ДД2, ДД3 = Неопределено, ДД4 = Неопределено, ДД5 = Неопределено, ДД6 = Неопределено, ДД7 = Неопределено) Экспорт
	
	Перем мФайлы, сч, ДД, мИмяФайла;
	
	мФайлы = Новый Массив;
	Для сч=1 По 7 Цикл
		ДД = ?(сч=1, ДД1, ?(сч=2, ДД2, ?(сч=3, ДД3, ?(сч=4, ДД4, ?(сч=5, ДД5, ?(сч=6, ДД6, ?(сч=7, ДД7, Неопределено)))))));
		Если ДД = Неопределено ИЛИ ТипЗнч(ДД) <> Тип("ДвоичныеДанные") Тогда
			Продолжить;
		ИначеЕсли ДД.Размер()<=0 Тогда
			Продолжить;
		КонецЕсли;
		мИмяФайла = ПолучитьИмяВременногоФайла();
		ДД.Записать(мИмяФайла);
		мФайлы.Добавить(мИмяФайла);
	КонецЦикла;
	
	мИмяФайла = ПолучитьИмяВременногоФайла();
	Если мФайлы.Количество()=0 Тогда
		Возврат Неопределено;
	ИначеЕсли мФайлы.Количество()=1 Тогда
		УдалитьФайлы(мИмяФайла);
		ДД = Новый ДвоичныеДанные(мФайлы[0]);
		УдалитьФайлы(мФайлы[0]);
		Возврат ДД;
	КонецЕсли;
	ОбъединитьФайлы(мФайлы, мИмяФайла);
	
	ДД = Новый ДвоичныеДанные(мИмяФайла);
	УдалитьФайлы(мИмяФайла);
	Для Каждого мИмяФайла из мФайлы Цикл 
		УдалитьФайлы(мИмяФайла); 
	КонецЦикла;
	
	Возврат ДД;
	
КонецФункции

#КонецОбласти

