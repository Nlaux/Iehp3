using Sitecore.Data.Items;
using System.Collections.Generic;

namespace iehp.HwVideoWidget.Models
{
    public class EventViewModel
    {
        public Item Item { get; set; }

        public List<Item> HwVideoWidgetList { get; set; }

        public string JavascriptToRun { get; set; }


    }
}