module AccordionHelper
  
  def accordion opts = {}
    opts[:accordion_id] ||= 'accordion'
    builder = AccordionBuilder.new opts, self
    content_tag :div, :class => 'accordion', :id => opts[:accordion_id] do
      yield builder
    end
  end
  
  class AccordionBuilder
    
    attr_reader :parent
    delegate :capture, :to => :parent
    
    def initialize opts, parent
      @first = true
      @parent = parent
      @opts = opts
    end
    
    def pane title, &block
      b = Builder::XmlMarkup.new
      b.div :class => 'accordion-group' do
        b.div :class => 'accordion-heading' do
          b.a title, :class => 'accordion-toggle', :'data-toggle' => 'collapse',
          :'data-parent' => "##{@opts[:accordion_id]}", :href => "##{title.parameterize}_pane"
        end
        css_class =  (@first && @opts[:open]) ? 'in' : ''
        @first = false
        b.div :class => "accordion-body collapse #{css_class}", :id => "#{title.parameterize}_pane" do
          b.div :class => 'accordion-inner' do
            b << capture(&block)
          end
        end
      end.html_safe
    end
  end
  
end
