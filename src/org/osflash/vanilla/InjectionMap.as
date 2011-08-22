package org.osflash.vanilla
{
	import org.osflash.vanilla.reflection.IInjectionMapSpi;

	public class InjectionMap implements IInjectionMapSpi
	{
		private var _constructorFields : Vector.<InjectionDetail> = new Vector.<InjectionDetail>();
		private var _fields : Object = {};
		private var _methods : Object = {};

		public function addConstructorField(injectionDetails : InjectionDetail) : void
		{
			_constructorFields.push(injectionDetails);
		}

		public function getConstructorFields() : Vector.<InjectionDetail>
		{
			return _constructorFields;
		}

		public function addField(fieldName : String, injectionDetails : InjectionDetail) : void
		{
			_fields[fieldName] = injectionDetails;
		}

		public function getFieldNames() : Vector.<String>
		{
			const result : Vector.<String> = new Vector.<String>();
			for (var fieldName : String in _fields)
			{
				result.push(fieldName);
			}
			return result;
		}

		public function getField(fieldName : String) : InjectionDetail
		{
			return _fields[fieldName];
		}

		public function addMethod(methodName : String, injectionDetails : InjectionDetail) : void
		{
			_methods[methodName] ||= new Vector.<InjectionDetail>();
			Vector.<InjectionDetail>(_methods[methodName]).push(injectionDetails);
		}

		public function getMethodsNames() : Vector.<String>
		{
			const result : Vector.<String> = new Vector.<String>();
			for (var methodName : String in _methods)
			{
				result.push(methodName);
			}
			return result;
		}

		public function getMethod(methodName : String) : Vector.<InjectionDetail>
		{
			return _methods[methodName];
		}

		public function toString() : String
		{
			var result : String = "[FieldMap ";

			result += "ctor:{" + _constructorFields + "}, ";

			result += "fields:{";
			for (var fieldName : String in _fields)
			{
				result += fieldName + "(" + getField(fieldName) + "),";
			}
			result += "}";

			result += "methods:{";
			for (var methodName : String in _methods)
			{
				result += methodName + "(" + getMethod(methodName) + "),";
			}
			result += "}";

			result += "]";
			return result;
		}
	}
}
