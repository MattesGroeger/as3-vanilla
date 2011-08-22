package org.osflash.vanilla.reflection
{
	import org.osflash.vanilla.InjectionDetail;
	
	public interface IInjectionMapSpi
	{
		function addConstructorField(injectionDetails : InjectionDetail) : void;

		function addField(fieldName : String, injectionDetails : InjectionDetail) : void;
		
		function addMethod(methodName : String, injectionDetails : InjectionDetail) : void;
	}
}