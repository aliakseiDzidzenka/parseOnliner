require "capybara"
require "selenium-webdriver"
require "csv"

# без указания этого пути у меня не находило веб-драйвер 
Selenium::WebDriver::Firefox.driver_path = "driver/geckodriver"
Capybara.default_driver = :selenium

# массивы для хранение результатов поиска
descriptions = []
headers = []
images = []

# Создаю сессию и захожу на онлайнер
session = Capybara.current_session
url = "https://onliner.by"
session.visit(url)


# скроллинг страницы, чтобы изображения подгрузились
1000.times {session.execute_script("window.scrollBy(0,100)")}

# на новостях справа в каждом разделе абзац с описнием скрыт
# чтобы его сделать видимым я исполняю это js-скрипт
session.execute_script("x = document.getElementsByTagName('p'); for(i=0;i<x.length;i++) x[i].setAttribute('style', 'display: block');")

# нахожу все изображения у которых в src есть слово news, т.к. они тогда являются картинкой новости
# и пушу все значения src в массив
session.find_all("figure a img", visible: :all).each { |e| images.push(e['src']) if /.+news.+.[jpeg|png|jpg]/.match(e['src'])}

# внутри всех элементов с классом b-main-page-grid-4 ищу описание новости и заголовок
session.find_all(".b-main-page-grid-4").each do |e| 
  e.find_all("p", visible: :all).each do |par| 
    # т.к. в результаты попадут описание тем форума, 
    # то в массив с описанием пушим ровно столько элементов, сколько в массивы изображений
    descriptions.push(par.text) if descriptions.length < images.length
  end
  
  # нахожу заголовки новостей и пушу в массив те, что не ссылаются на темы форума
  e.find_all("article h2 a, h3 a").each { |h| headers.push(h.text) if /.+forum.+/.match(h['href']) == nil }
end

# массив для строк csv
csv_rows = []

#зипаю все три массива и заполняю массив строк для csv
images.zip(headers).zip(descriptions).each {|a,b,c| csv_rows << [a,b,c] }

# создаю файл и заполняю его данными
CSV.open('../results.csv', 'wb') do |csv|
   csv_rows.each do |csv_row|
   csv << csv_row
  end
end
