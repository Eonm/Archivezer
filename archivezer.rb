#!/usr/bin/ruby
require 'optparse'
require 'clipboard'
require 'fileutils'

$folder = File.basename(Dir.getwd)
$absolute_path = Dir.pwd

description = "* __Auteur__ : \n* __Description__ : \n* __Sujets__ : \n* __Titre__ : \n* __Éditeur__ : \n* __Cote__ : \n \n---"

folder_icon = "[Desktop Entry]\nIcon=folder-red"

def update_links
	Dir.glob("**/*.pdf").each do |pdf|
		pdf_path = File.dirname(pdf)
		FileUtils.ln_s "#{$absolute_path}/#{pdf}","#{$absolute_path}/#{$folder}_PDF/#{pdf}"
	end
end

def zotero_api
	

end

options = {:repository => nil, :cote => nil, :pdf => nil, :link => "*"}

parser = OptionParser.new do|opts|
	opts.banner = "Usage: Archivezer.rb [options]"

	opts.on('-a', '--add add', 'Add cote') do |cote|
		options[:cote] = cote;

		puts $folder
  	FileUtils.mkdir("#{$folder}_#{cote}")
		FileUtils.touch("#{$folder}_#{cote}/#{$folder}_#{cote}.md")

		system("echo \"#{description.to_s}\" >> #{$folder}_#{cote}/#{$folder}_#{cote}.md")
		system("nano #{$folder}_#{cote}/#{$folder}_#{cote}.md") #Init cote and open within nano

		Clipboard.copy("* #{cote}")
		system("notify-send -t 3000 \"Cote copiée dans le presse papier\"")
		system("nano #{$folder}_#{cote}.md")
		update_links

		if system('git rev-parse') == true
     	`git add #{$folder}_#{cote}/#{$folder}_#{cote}.md && git commit -am "Add #{cote}.md"`
		end
	end

	opts.on('-i', '--init init', 'Init repository') do |repository|
		options[:repository] = repository;

		FileUtils.mkdir_p("#{repository}/#{repository}_PDF")
		FileUtils.touch("#{repository}/#{repository}_cotes.md");  FileUtils.touch("#{repository}/#{repository}_PDF/.directory")

		system("echo \"#{folder_icon.to_s}\" >> #{repository}/#{repository}_PDF/.directory")
		system("nano #{repository}/#{repository}_cotes.md")

		if system('git rev-parse') == true
    	`git add #{repository}/#{repository}_cotes.md && git commit -am "Add #{repository}_cotes.md"`
		end
	end

	opts.on('-p', '--pdf pdf', 'Convert to PDF') do |pdf|
   	options[:pdf] = pdf;
   	image_quality = pdf

    FileUtils.mkdir(["#{$folder}_LowRes","#{$folder}_NormalRes","PDF"])

    files = Dir.glob("*.jpg")
    files.each{|file|
      `convert -quality #{image_quality}% #{file} #{$folder}_LowRes/#{file}`
			system("convert #{$folder}_LowRes/#{file} -channel RGB  -contrast-stretch 0.25x0.25% #{$folder}_LowRes/#{file}")
			`convert #{$folder}_LowRes/#{file} #{$folder}_LowRes/out_#{file}.pdf`
      FileUtils.mv "#{file}","#{$folder}_NormalRes/"

    }

    `pdfunite #{$folder}_LowRes/*.pdf PDF/#{$folder}.pdf`
    remove("#{$folder}_LowRes/*.pdf")

		if system('git rev-parse') == true
	    `git add #{$folder}_NormalRes/* && git commit -am "Add #{$folder}_NormalRes images"`
	    `git add #{$folder}_LowRes/* && git commit -am "Add #{$folder}_LowRes images"`
	    `git add PDF/#{$folder}.pdf && git commit -am "Add #{$folder}.pdf"`
	 	end
	end

	opts.on('-u', '--update update', 'Update link') do |link|
	 update_links
	end

	opts.on('-h', '--help', 'Displays Help') do
		puts opts
		exit
	end
end

parser.parse!
