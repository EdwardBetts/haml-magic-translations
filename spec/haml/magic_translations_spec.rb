require 'spec_helper'

module Haml
  describe MagicTranslations do
    context 'Haml magic translations with I18n' do
      before(:all) do
        Haml::Template.enable_magic_translations(:i18n)
        I18n.load_path += Dir[File.join(File.dirname(__FILE__), "../locales/*.{po}")]
      end

      it 'should allow to set :magic_translations option in Haml::Template' do
        Haml::Template.options.key?(:magic_translations).should be_true
      end

      it 'should translate text using existing locales' do
        Haml::Template.options[:magic_translations] = true
        I18n.locale = :pl
        render(<<-'HAML'.strip_heredoc).should == <<-'HTML'.strip_heredoc
          %p Magic translations works!
          %p Here with interpolation, and everything thanks to #{I18n.name} and #{GetText.name}
        HAML
          <p>Magiczne tłumaczenie działa!</p>
          <p>A tutaj razem z interpolacją, a to wszystko dzięki połączeniu I18n i GetText</p>
        HTML
      end

      it 'should leave text without changes when translation is not available' do
        Haml::Template.options[:magic_translations] = true
        I18n.locale = :pl
        render(<<-'HAML'.strip_heredoc).should == <<-'HTML'.strip_heredoc
          %p Untranslated thanks to #{I18n.name} and #{GetText.name}
        HAML
          <p>Untranslated thanks to I18n and GetText</p>
        HTML
      end

      it 'should translate text with multiline plain text' do
        Haml::Template.options[:magic_translations] = true
        I18n.locale = :pl
       render(<<-'HAML'.strip_heredoc).should == <<-'HTML'.strip_heredoc
          %p Magic translations works!
          %p
            Now we will check multiline strings,
            which should be also translated,
            with interpolation #{'Interpolation'.upcase}
        HAML
          <p>Magiczne tłumaczenie działa!</p>
          <p>
            Kolejny wieloliniowy tekst,
            który powinien zostać przetłumaczony,
            interpolacja INTERPOLATION też działa!
          </p>
        HTML
      end

      it 'should not translate evaluated tags' do
        Haml::Template.options[:magic_translations] = true
        I18n.locale = :pl
        render(<<-HAML.strip_heredoc).should == <<-HTML.strip_heredoc
          %p= 'Magic translations works!'
        HAML
          <p>Magic translations works!</p>
        HTML
      end

      context 'when translating strings in Javascript' do
        before(:each) do
          Haml::Template.options[:magic_translations] = true
          I18n.locale = :pl
        end
        it "should translate strings inside _('')" do
          render(<<-'HAML'.strip_heredoc).should == <<-'HTML'.strip_heredoc
            :javascript
              var text = _('Magic translations works!');
          HAML
            <script type='text/javascript'>
              //<![CDATA[
                var text = "Magiczne t\u0142umaczenie dzia\u0142a!";
              //]]>
            </script>
          HTML
        end
        it 'should translate strings inside _("")' do
          render(<<-'HAML'.strip_heredoc).should == <<-'HTML'.strip_heredoc
            :javascript
              var text = _("Magic translations works!");
          HAML
            <script type='text/javascript'>
              //<![CDATA[
                var text = "Magiczne t\u0142umaczenie dzia\u0142a!";
              //]]>
            </script>
          HTML
        end
      end

      context 'when translating strings in Markdown' do
        before(:each) do
          Haml::Template.options[:magic_translations] = true
          I18n.locale = :pl
        end
        it "should translate strings inside _('')" do
          render(<<-'HAML'.strip_heredoc).should == <<-'HTML'.strip_heredoc
            :markdown
              Magic translations works!
          HAML
            <p>Magiczne tłumaczenie działa!</p>
          HTML
        end
      end

      context 'when disabling magic translations' do
        it 'should leave text untranslated' do
          Haml::Template.options[:magic_translations] = false
          I18n.locale = :pl
          render(<<-'HAML'.strip_heredoc).should == <<-'HTML'.strip_heredoc
            %p Magic translations works!
          HAML
            <p>Magic translations works!</p>
          HTML
        end
      end
    end
  end
end
