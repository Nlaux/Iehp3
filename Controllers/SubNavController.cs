using iehp.SubNav.Models;
using Sitecore;
using Sitecore.Data;
using Sitecore.Mvc.Controllers;
using System.Linq;
using System.Web.Mvc;

namespace iehp.Controllers
{
    public class SubNavController : SitecoreController
    {
        public ViewResult SubNavCtrl()
        {

            //read in config file & get parentGuid value
            var parentGuidValue = Sitecore.Configuration.Settings.GetSetting("subNavMenuFolderGuid");
            var parentGuidValue2 = Sitecore.Configuration.Settings.GetSetting("subNavDropdownMenuFolderGuid");

            //init Sitecore db 
            Database database = Context.Database;

            var model = new NavigationViewModel();
            model.Item = database.GetItem(parentGuidValue);
            model.Item2 = database.GetItem(parentGuidValue2);
            model.Children = model.Item.Children.ToList();
            model.Children2 = model.Item.Children.ToList();

            return View("/Views/Components/SubNavCtrl.cshtml", model);
        }
    }
}