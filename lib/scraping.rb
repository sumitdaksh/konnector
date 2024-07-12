module Scraping
  def self.web_site_data(parmas_data)
    begin
      # parmas_data = {
      #   "n": 10,
      #   "filters": {
      #     "batch": "W21",
      #     "industry": "Healthcare",
      #     # "regions": "United States of America",
      #     # "top_company": "Top Companies",
      #     # "tags": "B2B",
      #     # "team_size": "1-10",
      #     "isHiring": false,
      #     "nonprofit": false,
      #     "highlight_black": false,
      #     "highlight_latinx": false,
      #     "highlight_women": false
      #   }
      # }

      data = []
      if parmas_data.fetch(:filters, nil).present?
        parmas_data[:filters][:team_size] = parmas_data[:filters][:team_size].split('-').to_s if parmas_data[:filters].fetch(:team_size, nil).present?
        query_string = parmas_data[:filters].to_query
        url = 'https://www.ycombinator.com/companies?' + query_string
      else
        url = 'https://www.ycombinator.com/companies'
      end

      doc = Nokogiri::HTML(connect_driver(url, 5, 10))
      content = doc.css('._company_86jzd_338')
      content.each do |company|
        child_url = "https://www.ycombinator.com#{company.attribute_nodes[1].text}"
        child_data = Nokogiri::HTML(connect_driver(child_url))
        web_site_url = child_data.css('.group').css('a').text
        founder_names = []
        child_data.css('.space-y-5').children.each do |chi|
          founder_names << [chi.css('h3').text, chi.css('.bg-image-linkedin')[0].attribute_nodes[0].text]
        end
        if founder_names.empty?
          child_data.css('.space-y-4').children.each do |chi|
            founder_names << [chi.css('.leading-snug').css('.font-bold').text, chi.css('.bg-image-linkedin')[0].attribute_nodes[0].text]
          end
        end
        data << {
          name: company.css('div').css('span')[0].text,
          location: company.css('div').css('span')[1].text,
          industry: company.css('div').css('span')[4].text,
          description: company.css('div').css('span')[2].text,
          url: child_url,
          web_site_url: web_site_url,
          founder_names: founder_names
        }
      end
      create_csv(data)
    rescue => e
      puts e
    end
  end

  def self.create_csv(data)
    CSV.open("ycomb.csv", "wb", write_headers: true, headers: ["name", "location", "industry", "description", "url", "web_site_url", "founder_names_and_linked_in_url"]) do |csv|
      data.each do |data_ex|
        csv << [data_ex[:name], data_ex[:location], data_ex[:industry], data_ex[:description], data_ex[:url], data_ex[:web_site_url], data_ex[:founder_names]]
      end
    end
  end

  def self.connect_driver(url, seconds=0, scrolls=1)
    # Create a new instance of the Chrome driver
    options = Selenium::WebDriver::Chrome::Options.new(args: ['headless']) # Run in headless mode
    driver = Selenium::WebDriver.for(:chrome, options: options)
    # Open the webpage
    driver.navigate.to url

    sleep(seconds)
    if scrolls > 1
    scrolling_script = "
      // scroll down the page 10 times
      const scrolls = #{scrolls}
      let scrollCount = 0

      // scroll down and then wait for 0.5s
      const scrollInterval = setInterval(() => {
        window.scrollTo(0, document.body.scrollHeight)
        scrollCount++

        if (scrollCount === numScrolls) {
            clearInterval(scrollInterval)
        }
      }, 500)
  ";

    driver.execute_script(scrolling_script)
    sleep(seconds)
    end
    # Get the page source
    html = driver.page_source

    # Close the browser
    driver.quit
    return html
  end

end
